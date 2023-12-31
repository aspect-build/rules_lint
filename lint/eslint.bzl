"""API for calling declaring an ESLint lint aspect.

Typical usage:

```
load("@aspect_rules_lint//lint:eslint.bzl", "eslint_aspect")

eslint = eslint_aspect(
    binary = "@@//path/to:eslint",
    configs = "@@//path/to:eslintrc",
)
```

### With ts_project

Note, when used with `ts_project` and a custom `transpiler`,
the macro expands to several targets,
see https://github.com/aspect-build/rules_ts/blob/main/docs/transpiler.md#macro-expansion.

Since you want to lint the original TypeScript source files, the `ts_project` rule produced
by the macro is the one you want to lint, so when used with an `eslint_test` you should use
the `[name]_typings` label:

```
ts_project(
    name = "my_ts",
    transpiler = swc,
    ...
)

eslint_test(
    name = "lint_my_ts",
    srcs = [":my_ts_typings"],
)
```

See the [react example](https://github.com/bazelbuild/examples/blob/b498bb106b2028b531ceffbd10cc89530814a177/frontend/react/src/BUILD.bazel#L86-L92)
"""

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "COPY_FILE_TO_BIN_TOOLCHAINS", "copy_files_to_bin_actions")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("//lint/private:lint_aspect.bzl", "patch_and_report_files")

_MNEMONIC = "ESLint"

def _gather_inputs(ctx, srcs):
    inputs = copy_files_to_bin_actions(ctx, srcs)

    # Add the config file along with any deps it has on npm packages
    inputs.extend(js_lib_helpers.gather_files_from_js_providers(
        ctx.attr._config_files + [ctx.attr._workaround_17660, ctx.attr._formatter],
        include_transitive_sources = True,
        include_declarations = False,
        include_npm_linked_packages = True,
    ).to_list())

    return inputs

def eslint_action(ctx, executable, srcs, report, use_exit_code = False):
    """Create a Bazel Action that spawns an eslint process.

    Adapter for wrapping Bazel around
    https://eslint.org/docs/latest/use/command-line-interface

    Args:
        ctx: an action context OR aspect context
        executable: struct with an eslint field
        srcs: list of file objects to lint
        report: output: the stdout of eslint containing any violations found
        use_exit_code: whether an eslint process exiting non-zero will be a build failure
    """

    args = ctx.actions.args()

    # TODO: enable if debug config, similar to rules_ts
    # args.add("--debug")

    args.add_all(["--format", "../../../" + ctx.file._formatter.path])
    args.add_all([s.short_path for s in srcs])

    env = {"BAZEL_BINDIR": ctx.bin_dir.path}

    if use_exit_code:
        ctx.actions.run_shell(
            inputs = _gather_inputs(ctx, srcs),
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
            inputs = _gather_inputs(ctx, srcs),
            outputs = [report, exit_code_out],
            executable = executable._eslint,
            arguments = [args],
            env = env,
            mnemonic = _MNEMONIC,
        )

def eslint_fix(ctx, executable, srcs, patch):
    """Create a Bazel Action that spawns eslint with --fix.

    Args:
        ctx: an action context OR aspect context
        executable: struct with an eslint field
        srcs: list of file objects to lint
        patch: output file containing the applied fixes that can be applied with the patch(1) command.
    """
    patch_cfg = ctx.actions.declare_file("_{}.patch_cfg".format(ctx.label.name))

    bin_srcs = copy_files_to_bin_actions(ctx, srcs)

    ctx.actions.write(
        output = patch_cfg,
        content = json.encode({
            "linter": executable._eslint.path,
            "args": ["--fix"] + [s.short_path for s in srcs],
            "env": {"BAZEL_BINDIR": ctx.bin_dir.path},
            "files_to_diff": [s.path for s in bin_srcs],
            "output": patch.path,
        }),
    )

    ctx.actions.run(
        inputs = _gather_inputs(ctx, srcs) + [patch_cfg],
        outputs = [patch],
        executable = executable._patcher,
        arguments = [patch_cfg.path],
        env = {"BAZEL_BINDIR": "."},
        tools = [executable._eslint],
        mnemonic = _MNEMONIC,
    )

# buildifier: disable=function-docstring
def _eslint_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["js_library", "ts_project", "ts_project_rule"]:
        return []

    patch, report, info = patch_and_report_files(_MNEMONIC, target, ctx)
    eslint_action(ctx, ctx.executable, ctx.rule.files.srcs, report, ctx.attr.fail_on_violation)
    eslint_fix(ctx, ctx.executable, ctx.rule.files.srcs, patch)
    return [info]

def eslint_aspect(binary, configs):
    """A factory function to create a linter aspect.

    Args:
        binary: the eslint binary, typically a rule like

            ```
            load("@npm//:eslint/package_json.bzl", eslint_bin = "bin")
            eslint_bin.eslint_binary(name = "eslint")
            ```
        configs: label(s) of the eslint config file(s)
    """

    # syntax-sugar: allow a single config file in addition to a list
    if type(configs) == "string":
        configs = [configs]
    return aspect(
        implementation = _eslint_aspect_impl,
        attrs = {
            "fail_on_violation": attr.bool(),
            "_eslint": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config_files": attr.label_list(
                default = configs,
                allow_files = True,
            ),
            "_patcher": attr.label(
                default = "@aspect_rules_lint//lint/private:patcher",
                executable = True,
                cfg = "exec",
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
        toolchains = COPY_FILE_TO_BIN_TOOLCHAINS,
    )
