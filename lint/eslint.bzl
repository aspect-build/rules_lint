"""API for calling declaring an ESLint lint aspect.

Typical usage:

```
load("@aspect_rules_lint//lint:eslint.bzl", "eslint_aspect")

eslint = eslint_aspect(
    binary = "@@//path/to:eslint",
    config = "@@//path/to:eslintrc",
)
```
"""

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_files_to_bin_actions")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("//lint/private:lint_aspect.bzl", "report_file")

_MNEMONIC = "ESLint"

def eslint_action(ctx, executable, srcs, report, use_exit_code = False):
    """Create a Bazel Action that spawns an eslint process.

    Adapter for wrapping Bazel around
    https://eslint.org/docs/latest/use/command-line-interface

    Args:
        ctx: an action context OR aspect context
        executable: struct with an eslint field
        srcs: list of file objects to lint
        report: output to create
        use_exit_code: whether an eslint process exiting non-zero will be a build failure
    """

    args = ctx.actions.args()

    # require explicit path to the eslintrc file, don't search for one
    args.add("--no-eslintrc")

    # TODO: enable if debug config, similar to rules_ts
    # args.add("--debug")

    args.add_all(["--config", ctx.file._config_file.short_path])
    args.add_all(["--format", "../../../" + ctx.file._formatter.path])
    args.add_all([s.short_path for s in srcs])

    env = {"BAZEL_BINDIR": ctx.bin_dir.path}

    inputs = copy_files_to_bin_actions(ctx, srcs)

    # Add the config file along with any deps it has on npm packages
    inputs.extend(js_lib_helpers.gather_files_from_js_providers(
        [ctx.attr._config_file, ctx.attr._workaround_17660, ctx.attr._formatter],
        include_transitive_sources = True,
        include_declarations = False,
        include_npm_linked_packages = True,
    ).to_list())

    if use_exit_code:
        ctx.actions.run_shell(
            inputs = inputs,
            outputs = [report],
            tools = [executable._eslint],
            arguments = [args],
            command = executable._eslint.path + " $@ && touch " + report.path,
            env = env,
            mnemonic = _MNEMONIC,
        )
    else:
        # Workaround: create an empty report file in case eslint doesn't write one
        # Use `../../..` to return to the execroot?
        args.add_joined(["--node_options", "--require", "../../../" + ctx.file._workaround_17660.path], join_with = "=")

        args.add_all(["--output-file", report.short_path])
        exit_code_out = ctx.actions.declare_file("_{}.exit_code_out".format(ctx.label.name))
        env["JS_BINARY__EXIT_CODE_OUTPUT_FILE"] = exit_code_out.path

        ctx.actions.run(
            inputs = inputs,
            outputs = [report, exit_code_out],
            executable = executable._eslint,
            arguments = [args],
            env = env,
            mnemonic = _MNEMONIC,
        )

# buildifier: disable=function-docstring
def _eslint_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["js_binary", "js_library", "ts_project", "ts_project_rule"]:
        return []
    if not hasattr(ctx.rule.files, "srcs"):
        return []

    report, info = report_file(_MNEMONIC, target, ctx)
    eslint_action(ctx, ctx.executable, ctx.rule.files.srcs, report, ctx.attr.fail_on_violation)
    return [info]

def eslint_aspect(binary, config):
    """A factory function to create a linter aspect.

    Args:
        binary: the eslint binary, typically a rule like

            ```
            load("@npm//:eslint/package_json.bzl", eslint_bin = "bin")
            eslint_bin.eslint_binary(name = "eslint")
            ```
        config: label of the eslint config file
    """
    return aspect(
        implementation = _eslint_aspect_impl,
        attrs = {
            "fail_on_violation": attr.bool(),
            "_eslint": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(
                default = config,
                allow_single_file = True,
            ),
            "_workaround_17660": attr.label(
                default = "@aspect_rules_lint//lint:eslint.workaround_17660",
                allow_single_file = True,
                cfg = "exec",
            ),
            "_formatter": attr.label(
                default = "@aspect_rules_lint//lint:eslint.bazel-formatter",
                allow_single_file = True,
                cfg = "exec",
            ),
        },
    )
