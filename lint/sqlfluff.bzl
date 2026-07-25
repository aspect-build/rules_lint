"""Configures [SQLFluff](https://sqlfluff.com/) to run as a Bazel aspect.

Typical usage:

Create an executable target for SQLFluff, for example in `tools/lint/BUILD.bazel`:

```starlark
load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

py_console_script_binary(
    name = "sqlfluff",
    pkg = "@pip//sqlfluff:pkg",
)
```

Then declare the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:sqlfluff.bzl", "lint_sqlfluff_aspect")

sqlfluff = lint_sqlfluff_aspect(
    binary = Label("//tools/lint:sqlfluff"),
    config = Label("//:.sqlfluff"),
)
```

SQLFluff 4.0.3 or newer is required for SARIF output, and the configuration must select a SQL
dialect. Finally, opt SQL sources into linting by tagging a `filegroup` with `sql` or
`lint-with-sqlfluff`, or by providing a custom `rule_kinds` list that matches your SQL rules.
Files in a visited target's `data` attribute are available to SQLFluff templaters without being
linted themselves.

Bazel target membership selects candidate files, while SQLFluff's `sql_file_exts` configuration
determines which candidates are SQL. `.sqlfluffignore` files are not consulted; use the standard
`no-lint` tag or exclude files from the target instead.
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "noop_lint_action", "output_files", "patch_and_output_files", "should_visit")
load("//lint/private:patcher_action.bzl", "patcher_attrs", "run_patcher")

_MNEMONIC = "AspectRulesLintSQLFluff"
_JQ_TOOLCHAIN = Label("@jq.bzl//jq/toolchain:type")
_SARIF_FILTER = "del(.runs[].invocations[]?.startTimeUtc, .runs[].invocations[]?.endTimeUtc)"

def sqlfluff_action(
        ctx,
        executable,
        srcs,
        config,
        stdout,
        exit_code = None,
        data = [],
        format = None,
        options = [],
        patch = None,
        use_color = False):
    """Run SQLFluff as an action under Bazel.

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: File representing the SQLFluff program
        srcs: SQL files to lint
        config: SQLFluff configuration file
        stdout: output file for SQLFluff stdout
        exit_code: optional output file for exit code. If absent, non-zero exits fail the build.
        data: additional files required by the configuration or templater
        format: optional output format passed via `--format`
        options: additional command-line options
        patch: optional patch output. When present, runs `sqlfluff fix` and records its edits.
        use_color: whether to emit color in human-readable output
    """
    inputs = list(srcs) + data + [config]

    args = ctx.actions.args()
    args.add("fix" if patch != None else "lint")
    args.add("--disable-progress-bar")
    args.add("--disregard-sqlfluffignores")
    args.add("--ignore-local-config")
    args.add("--color" if use_color else "--nocolor")
    args.add("--config", config)
    args.add_all(options)
    if format:
        args.add("--format", format)
    args.add_all(srcs)

    if patch != None:
        run_patcher(
            ctx,
            ctx.executable,
            inputs = inputs,
            args = args,
            files_to_diff = [s.path for s in srcs],
            patch_out = patch,
            tools = [executable],
            stdout = stdout,
            exit_code = exit_code,
            mnemonic = _MNEMONIC,
            progress_message = "Fixing %{label} with SQLFluff",
        )
        return

    outputs = [stdout]
    tools = [executable]
    if format == "sarif":
        jq = ctx.toolchains[_JQ_TOOLCHAIN].jqinfo.bin
        tools.append(jq)
        if exit_code:
            command = """set -o pipefail
{sqlfluff} "$@" | {jq} '{filter}' >{stdout}
statuses=("${{PIPESTATUS[@]}}")
echo "${{statuses[0]}}" >{exit_code}
exit "${{statuses[1]}}"
""".format(
                sqlfluff = executable.path,
                jq = jq.path,
                filter = _SARIF_FILTER,
                stdout = stdout.path,
                exit_code = exit_code.path,
            )
            outputs.append(exit_code)
        else:
            command = "set -o pipefail\n{sqlfluff} \"$@\" | {jq} '{filter}' >{stdout}".format(
                sqlfluff = executable.path,
                jq = jq.path,
                filter = _SARIF_FILTER,
                stdout = stdout.path,
            )
    elif exit_code:
        command = "{sqlfluff} \"$@\" >{stdout}; echo $? >{exit_code}".format(
            sqlfluff = executable.path,
            stdout = stdout.path,
            exit_code = exit_code.path,
        )
        outputs.append(exit_code)
    else:
        command = "{sqlfluff} \"$@\" >{stdout}".format(
            sqlfluff = executable.path,
            stdout = stdout.path,
        )

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        arguments = [args],
        tools = tools,
        command = command,
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with SQLFluff",
        toolchain = _JQ_TOOLCHAIN if format == "sarif" else None,
    )

# buildifier: disable=function-docstring
def _sqlfluff_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds, ctx.attr._filegroup_tags):
        return []

    files_to_lint = filter_srcs(ctx.rule)
    target_data = ctx.rule.files.data if hasattr(ctx.rule.attr, "data") else []
    action_data = depset(ctx.files._data + target_data).to_list()
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    sqlfluff_action(
        ctx,
        ctx.executable._sqlfluff,
        files_to_lint,
        ctx.file._config_file,
        outputs.human.out,
        outputs.human.exit_code,
        data = action_data,
        options = ctx.attr._extra_args,
        patch = getattr(outputs, "patch", None),
        use_color = ctx.attr._options[LintOptionsInfo].color,
    )
    sqlfluff_action(
        ctx,
        ctx.executable._sqlfluff,
        files_to_lint,
        ctx.file._config_file,
        outputs.machine.out,
        outputs.machine.exit_code,
        data = action_data,
        format = "sarif",
        options = ctx.attr._extra_args,
    )
    return [info]

def lint_sqlfluff_aspect(
        binary,
        config,
        data = [],
        rule_kinds = ["sql_library"],
        filegroup_tags = ["sql", "lint-with-sqlfluff"],
        extra_args = []):
    """Create a SQLFluff aspect.

    Args:
        binary: a SQLFluff 4.0.3 or newer executable
        config: SQLFluff configuration file, which must select a SQL dialect
        data: additional files required by the configuration or templater for every visited target
        rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect
        filegroup_tags: filegroups tagged with these tags will also be visited by the aspect
        extra_args: additional command-line options passed to SQLFluff
    """
    return aspect(
        implementation = _sqlfluff_aspect_impl,
        attrs = patcher_attrs | {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_sqlfluff": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(
                default = config,
                allow_single_file = True,
            ),
            "_data": attr.label_list(
                default = data,
                allow_files = True,
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
            "_filegroup_tags": attr.string_list(
                default = filegroup_tags,
            ),
            "_extra_args": attr.string_list(
                default = extra_args,
            ),
        },
        toolchains = [_JQ_TOOLCHAIN],
    )
