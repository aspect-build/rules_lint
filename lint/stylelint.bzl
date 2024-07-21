"""Configures [Stylelint](https://stylelint.io/) to run as a Bazel aspect

First, all CSS sources must be the srcs of some Bazel rule.
You can use a `filegroup` with `lint-with-stylelint` in the `tags`:

```python
filegroup(
    name = "css",
    srcs = glob(["*.css"]),
    tags = ["lint-with-stylelint"],
)
```

See the `filegroup_tags` and `rule_kinds` attributes below to customize this behavior.

## Usage

Add `stylelint` as a `devDependency` in your `package.json`, and declare a binary target for Bazel to execute it.

For example in `tools/lint/BUILD.bazel`:

```starlark
load("@npm//:stylelint/package_json.bzl", stylelint_bin = "bin")
stylelint_bin.stylelint_binary(name = "stylelint")
```

Then declare the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:stylelint.bzl", "lint_stylelint_aspect")
stylelint = lint_stylelint_aspect(
    binary = "@@//tools/lint:stylelint",
    config = "@@//:stylelintrc",
)
```

Finally, register the aspect with your linting workflow, such as in `.aspect/cli/config.yaml` for `aspect lint`.
"""

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "COPY_FILE_TO_BIN_TOOLCHAINS", "copy_files_to_bin_actions")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "output_files", "patch_and_output_files", "should_visit")

_MNEMONIC = "AspectRulesLintStylelint"

def stylelint_action(ctx, executable, srcs, config, stderr, exit_code = None, env = {}, options = []):
    """Spawn stylelint as a Bazel action

    Args:
        ctx: an action context OR aspect context
        executable: struct with an _stylelint field
        srcs: list of file objects to lint
        config: js_library representing the config file (and its dependencies)
        stderr: output file containing the stderr or --output-file of stylelint
        exit_code: output file containing the exit code of stylelint.
            If None, then fail the build when stylelint exits non-zero.
            Exit codes may be:
                1 - fatal error
                2 - lint problem
                64 - invalid CLI usage
                78 - invalid configuration file
        env: environment variables for stylelint
        options: additional command-line arguments
    """
    inputs = copy_files_to_bin_actions(ctx, srcs + config)
    outputs = [stderr]

    # Wire command-line options, see https://stylelint.io/user-guide/cli#options
    args = ctx.actions.args()
    args.add_all(options)
    args.add_all(srcs)

    if exit_code:
        command = "{stylelint} $@ 2>{stderr}; echo $? >" + exit_code.path
        outputs.append(exit_code)
    else:
        # Create empty file on success, as Bazel expects one
        command = "{stylelint} $@ && touch {stderr}"

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        command = command.format(stylelint = executable._stylelint.path, stderr = stderr.path),
        arguments = [args],
        mnemonic = _MNEMONIC,
        env = dict(env, **{
            "BAZEL_BINDIR": ctx.bin_dir.path,
        }),
        progress_message = "Linting %{label} with Stylelint",
        tools = [executable._stylelint],
    )

def stylelint_fix(ctx, executable, srcs, config, patch, stderr, exit_code, env = {}, options = []):
    """Create a Bazel Action that spawns stylelint with --fix.

    Args:
        ctx: an action context OR aspect context
        executable: struct with a _stylelint field
        srcs: list of file objects to lint
        config: js_library representing the config file (and its dependencies)
        patch: output file containing the applied fixes that can be applied with the patch(1) command.
        stderr: output file containing the stderr or --output-file of stylelint
        exit_code: output file containing the exit code of stylelint
        env: environment variables for stylelint
        options: additional command line options
    """
    patch_cfg = ctx.actions.declare_file("_{}.patch_cfg".format(ctx.label.name))
    inputs = copy_files_to_bin_actions(ctx, srcs + config)
    args = ["--fix"]
    args.extend(options)
    args.extend([s.short_path for s in srcs])

    ctx.actions.write(
        output = patch_cfg,
        content = json.encode({
            "linter": executable._stylelint.path,
            "args": args,
            "env": dict(env, **{"BAZEL_BINDIR": ctx.bin_dir.path}),
            "files_to_diff": [s.path for s in srcs],
            "output": patch.path,
        }),
    )

    ctx.actions.run(
        inputs = inputs + [patch_cfg],
        outputs = [patch, stderr, exit_code],
        executable = executable._patcher,
        arguments = [patch_cfg.path],
        env = dict(env, **{
            "BAZEL_BINDIR": ".",
            "JS_BINARY__EXIT_CODE_OUTPUT_FILE": exit_code.path,
            "JS_BINARY__STDERR_OUTPUT_FILE": stderr.path,
            "JS_BINARY__SILENT_ON_SUCCESS": "1",
        }),
        tools = [executable._stylelint],
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with Stylelint",
    )

# buildifier: disable=function-docstring
def _stylelint_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds, ctx.attr._filegroup_tags):
        return []

    files_to_lint = filter_srcs(ctx.rule)
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    # https://stylelint.io/user-guide/cli#--color---no-color
    color_options = ["--color"] if ctx.attr._options[LintOptionsInfo].color else ["--no-color"]

    # stylelint can produce a patch file at the same time it reports the unpatched violations
    if hasattr(outputs, "patch"):
        stylelint_fix(ctx, ctx.executable, files_to_lint, ctx.files._config_file, outputs.patch, outputs.human.out, outputs.human.exit_code, options = color_options)
    else:
        stylelint_action(ctx, ctx.executable, files_to_lint, ctx.files._config_file, outputs.human.out, outputs.human.exit_code, options = color_options)

    # TODO(alex): if we run with --fix, this will report the issues that were fixed. Does a machine reader want to know about them?
    stylelint_action(ctx, ctx.executable, files_to_lint, ctx.files._config_file, outputs.machine.out, outputs.machine.exit_code, options = ["--formatter", "compact"])

    return [info]

def lint_stylelint_aspect(binary, config, rule_kinds = ["css_library"], filegroup_tags = ["lint-with-stylelint"]):
    """A factory function to create a linter aspect.

    Args:
        binary: the stylelint binary, typically a rule like

            ```
            load("@npm//:stylelint/package_json.bzl", stylelint_bin = "bin")
            stylelint_bin.stylelint_binary(name = "stylelint")
            ```
        config: label(s) of the stylelint config file(s)
        rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect
        filegroup_tags: which tags on a `filegroup` indicate that it should be visited by the aspect
    """

    return aspect(
        implementation = _stylelint_aspect_impl,
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_stylelint": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(
                default = config,
                allow_files = True,
            ),
            "_patcher": attr.label(
                default = "@aspect_rules_lint//lint/private:patcher",
                executable = True,
                cfg = "exec",
            ),
            "_filegroup_tags": attr.string_list(
                default = filegroup_tags,
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
        toolchains = COPY_FILE_TO_BIN_TOOLCHAINS,
    )
