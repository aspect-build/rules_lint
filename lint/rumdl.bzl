"""Configures [rumdl](https://github.com/rvben/rumdl) to lint Markdown files.

Markdown sources must belong to a `markdown_library` rule or to a `filegroup`
tagged with `markdown` or `lint-with-rumdl`.

Relative links can only resolve to files available in the Bazel sandbox. Pass
linked files that are not already sources through the `data` attribute.

Typical usage:

```starlark
load("@aspect_rules_lint//lint:rumdl.bzl", "lint_rumdl_aspect")

rumdl = lint_rumdl_aspect(
    binary = Label("@aspect_rules_lint//lint:rumdl_bin"),
    config = Label("//:.rumdl.toml"),
    data = [Label("//docs:link_targets")],
)
```
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "noop_lint_action", "output_files", "patch_and_output_files", "should_visit")
load("//lint/private:patcher_action.bzl", "patcher_attrs", "run_patcher")

_MNEMONIC = "AspectRulesLintRumdl"

_MARKDOWN_EXTENSIONS = (".md", ".mdx", ".qmd", ".Rmd")

def rumdl_action(ctx, executable, srcs, stdout, exit_code = None, config = None, data = [], output_format = None, args = [], patch = None):
    """Run rumdl as an action under Bazel.

    Args:
        ctx: Bazel rule or aspect evaluation context.
        executable: rumdl executable.
        srcs: Markdown files to lint.
        stdout: output file for rumdl diagnostics.
        exit_code: optional output file for the rumdl exit code. If absent, a
            non-zero exit fails the action.
        config: optional rumdl configuration file. When absent, rumdl runs with
            built-in defaults and does not discover configuration files.
        data: additional files available for local link resolution. Markdown
            files are also checked so rumdl can validate cross-file fragments.
        output_format: optional value for rumdl's `--output-format` flag.
        args: additional lint-selection command-line arguments passed to rumdl.
            Do not pass output, color, cache, or configuration flags, which are
            managed by the aspect.
        patch: optional output file for fixes. When present, rumdl edits sandbox
            copies and the standard rules_lint patcher records the changes.
    """
    inputs = srcs + data
    if config:
        inputs.append(config)

    action_args = ctx.actions.args()
    action_args.add("check")
    if config:
        action_args.add_all(["--config", config.path])
    else:
        action_args.add("--no-config")
    if output_format:
        action_args.add_all(["--output-format", output_format])
    action_args.add_all(args)
    files_to_check = depset(srcs + _markdown_files(data)).to_list()
    action_args.add_all([src.short_path for src in files_to_check])

    if patch:
        action_args.add("--fix")
        run_patcher(
            ctx,
            ctx.executable,
            inputs = inputs,
            args = action_args,
            files_to_diff = [file.path for file in files_to_check],
            patch_out = patch,
            tools = [executable],
            stdout = stdout,
            exit_code = exit_code,
            mnemonic = _MNEMONIC,
            progress_message = "Fixing %{label} with rumdl",
            patch_cfg_suffix = "rumdl.patch_cfg",
        )
        return

    outputs = [stdout]
    redirect = '>"{stdout}"' if output_format else '>"{stdout}" 2>&1'
    if exit_code:
        command = '"{rumdl}" "$@" {redirect}; echo $? > "{exit_code}"'.format(
            rumdl = executable.path,
            redirect = redirect.format(stdout = stdout.path),
            exit_code = exit_code.path,
        )
        outputs.append(exit_code)
    else:
        command = '"{rumdl}" "$@" {redirect}'.format(
            rumdl = executable.path,
            redirect = redirect.format(stdout = stdout.path),
        )

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        arguments = [action_args],
        tools = [executable],
        command = command,
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with rumdl",
    )

def _markdown_files(files):
    return [file for file in files if file.basename.endswith(_MARKDOWN_EXTENSIONS)]

# buildifier: disable=function-docstring
def _rumdl_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds, ctx.attr._filegroup_tags):
        return []

    files_to_lint = _markdown_files(filter_srcs(ctx.rule))
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)
    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    common_args = ctx.attr._args + [
        "--color",
        "always" if ctx.attr._options[LintOptionsInfo].color else "never",
        "--deny-config-warnings",
        "--no-cache",
        "--quiet",
    ]
    if ctx.attr._options[LintOptionsInfo].debug:
        common_args.append("--verbose")
    rumdl_action(
        ctx,
        ctx.executable._rumdl,
        files_to_lint,
        outputs.human.out,
        outputs.human.exit_code,
        config = ctx.file._config_file,
        data = ctx.files._data,
        args = common_args,
        patch = getattr(outputs, "patch", None),
    )
    rumdl_action(
        ctx,
        ctx.executable._rumdl,
        files_to_lint,
        outputs.machine.out,
        outputs.machine.exit_code,
        config = ctx.file._config_file,
        data = ctx.files._data,
        output_format = "sarif",
        args = ctx.attr._args + ["--color", "never", "--deny-config-warnings", "--no-cache"],
    )
    return [info]

def lint_rumdl_aspect(
        binary,
        config = None,
        data = [],
        rule_kinds = ["markdown_library"],
        filegroup_tags = ["markdown", "lint-with-rumdl"],
        args = []):
    """Create a rumdl lint aspect.

    Args:
        binary: a rumdl executable, such as `@aspect_rules_lint//lint:rumdl_bin`.
        config: optional rumdl configuration file. If omitted, only built-in
            defaults and command-line arguments are used.
        data: additional files to make available for local link resolution.
            Markdown files are also checked to validate cross-file fragments.
        rule_kinds: rule kinds visited by the aspect.
        filegroup_tags: tags that opt `filegroup` targets into rumdl linting.
        args: additional lint-selection command-line arguments passed to rumdl.
            Output, color, cache, and configuration flags are managed by the
            aspect and should not be included.

    Returns:
        An aspect definition for rumdl.
    """
    return aspect(
        implementation = _rumdl_aspect_impl,
        attrs = patcher_attrs | {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_rumdl": attr.label(
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
                doc = "Additional files available for local link resolution",
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
            "_filegroup_tags": attr.string_list(
                default = filegroup_tags,
            ),
            "_args": attr.string_list(
                default = args,
            ),
        },
    )
