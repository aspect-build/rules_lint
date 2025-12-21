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
    binary = Label("//tools/lint:stylelint"),
    config = Label("//:stylelintrc"),
)
```

Finally, register the aspect with your linting workflow, such as in `.aspect/cli/config.yaml` for `aspect lint`.
"""

load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("@bazel_lib//lib:copy_to_bin.bzl", "COPY_FILE_TO_BIN_TOOLCHAINS", "copy_files_to_bin_actions")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "output_files", "parse_to_sarif_action", "patch_and_output_files", "should_visit")
load("//lint/private:patcher_action.bzl", "patcher_attrs", "run_patcher")

_MNEMONIC = "AspectRulesLintStylelint"

def _gather_inputs(ctx, srcs, files = []):
    inputs = copy_files_to_bin_actions(ctx, srcs)

    # Add the config file along with any deps it has on npm packages
    if "gather_files_from_js_providers" in dir(js_lib_helpers):
        # rules_js 1.x
        js_inputs = js_lib_helpers.gather_files_from_js_providers(
            [ctx.attr._config_file] + files,
            include_transitive_sources = True,
            include_declarations = False,
            include_npm_linked_packages = True,
        )
    else:
        # rules_js 2.x
        js_inputs = js_lib_helpers.gather_files_from_js_infos(
            [ctx.attr._config_file] + files,
            include_sources = True,
            include_transitive_sources = True,
            include_types = False,
            include_transitive_types = False,
            include_npm_sources = True,
        )
    return depset(inputs, transitive = [js_inputs])

def stylelint_action(ctx, executable, srcs, stderr, exit_code = None, env = {}, options = [], format = None):
    """Spawn stylelint as a Bazel action

    Args:
        ctx: an action context OR aspect context
        executable: struct with an _stylelint field
        srcs: list of file objects to lint
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
        format: a formatter to add as a command line argument
    """
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

    file_inputs = []
    if type(format) == "string":
        args.add_all(["--formatter", format])
    elif format != None:
        args.add_all(["--custom-formatter", "../../../" + format.files.to_list()[0].path])
        file_inputs.append(format)

    ctx.actions.run_shell(
        inputs = _gather_inputs(ctx, srcs, file_inputs),
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

def stylelint_fix(ctx, executable, srcs, patch, stderr, exit_code, env = {}, options = []):
    """Create a Bazel Action that spawns stylelint with --fix.

    Args:
        ctx: an action context OR aspect context
        executable: struct with a _stylelint field
        srcs: list of file objects to lint
        patch: output file containing the applied fixes that can be applied with the patch(1) command.
        stderr: output file containing the stderr or --output-file of stylelint
        exit_code: output file containing the exit code of stylelint
        env: environment variables for stylelint
        options: additional command line options
    """
    args = ["--fix"]
    args.extend(options)
    args.extend([s.short_path for s in srcs])

    run_patcher(
        ctx,
        executable,
        inputs = _gather_inputs(ctx, srcs),
        args = args,
        files_to_diff = [s.path for s in srcs],
        patch_out = patch,
        tools = [executable._stylelint],
        patch_cfg_env = dict(env, **{"BAZEL_BINDIR": ctx.bin_dir.path}),
        # Capture stylelint's stdout output so the Bazel action
        # always produces a file (even on exit 0).
        # Similar to what Eslint currently does.
        stdout = stderr,
        stderr = stderr,
        exit_code = exit_code,
        env = env,
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
        stylelint_fix(ctx, ctx.executable, files_to_lint, outputs.patch, outputs.human.out, outputs.human.exit_code, options = color_options)
    else:
        stylelint_action(ctx, ctx.executable, files_to_lint, outputs.human.out, outputs.human.exit_code, options = color_options)

    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))

    # TODO(alex): if we run with --fix, this will report the issues that were fixed. Does a machine reader want to know about them?
    stylelint_action(ctx, ctx.executable, files_to_lint, raw_machine_report, outputs.machine.exit_code, format = ctx.attr._compact_formatter)

    # We could probably use https://www.npmjs.com/package/stylelint-sarif-formatter instead.
    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)

    return [info]

def lint_stylelint_aspect(binary, config, rule_kinds = ["css_library"], filegroup_tags = ["lint-with-stylelint"]):
    """A factory function to create a linter aspect.

    Args:
        binary: the stylelint binary, typically a rule like

            ```
            load("@npm//:stylelint/package_json.bzl", stylelint_bin = "bin")
            stylelint_bin.stylelint_binary(name = "stylelint")
            ```
        config: label(s) of the stylelint config file
        rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect
        filegroup_tags: which tags on a `filegroup` indicate that it should be visited by the aspect
    """

    return aspect(
        implementation = _stylelint_aspect_impl,
        attrs = patcher_attrs | {
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
            "_compact_formatter": attr.label(
                default = "@aspect_rules_lint//lint:stylelint.compact-formatter",
                allow_single_file = True,
                cfg = "exec",
            ),
            "_filegroup_tags": attr.string_list(
                default = filegroup_tags,
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
        toolchains = COPY_FILE_TO_BIN_TOOLCHAINS + [OPTIONAL_SARIF_PARSER_TOOLCHAIN],
    )
