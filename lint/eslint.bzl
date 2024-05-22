"""API for calling declaring an ESLint lint aspect.

Typical usage:

First, install eslint using your typical npm package.json and rules_js rules.

Next, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
load("@npm//:eslint/package_json.bzl", eslint_bin = "bin")
eslint_bin.eslint_binary(name = "eslint")
```

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:eslint.bzl", "eslint_aspect")

eslint = eslint_aspect(
    binary = "@@//tools/lint:eslint",
    # We trust that eslint will locate the correct configuration file for a given source file.
    # See https://eslint.org/docs/latest/use/configure/configuration-files#cascading-and-hierarchy
    configs = [
        "@@//:eslintrc",
        ...
    ],
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
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "patch_and_report_files", "report_files")

_MNEMONIC = "ESLint"

def _gather_inputs(ctx, srcs):
    inputs = copy_files_to_bin_actions(ctx, srcs)

    # Add the config file along with any deps it has on npm packages
    if "gather_files_from_js_providers" in dir(js_lib_helpers):
        # rules_js 1.x
        js_inputs = js_lib_helpers.gather_files_from_js_providers(
            ctx.attr._config_files + [ctx.attr._workaround_17660, ctx.attr._formatter],
            include_transitive_sources = True,
            include_declarations = True,
            include_npm_linked_packages = True,
        )
    else:
        # rules_js 2.x
        js_inputs = js_lib_helpers.gather_files_from_js_infos(
            ctx.attr._config_files + [ctx.attr._workaround_17660, ctx.attr._formatter],
            include_sources = True,
            include_transitive_sources = True,
            include_types = True,
            include_transitive_types = True,
            include_npm_sources = True,
        )
    inputs.extend(js_inputs.to_list())
    return inputs

def eslint_action(ctx, executable, srcs, report, exit_code = None):
    """Create a Bazel Action that spawns an eslint process.

    Adapter for wrapping Bazel around
    https://eslint.org/docs/latest/use/command-line-interface

    Args:
        ctx: an action context OR aspect context
        executable: struct with an eslint field
        srcs: list of file objects to lint
        report: output file containing the stdout or --output-file of eslint
        exit_code: output file containing the exit code of eslint.
            If None, then fail the build when eslint exits non-zero.
    """

    args = ctx.actions.args()

    # TODO: enable if debug config, similar to rules_ts
    # args.add("--debug")

    args.add_all(["--format", "../../../" + ctx.file._formatter.path])
    args.add_all([s.short_path for s in srcs])

    env = {"BAZEL_BINDIR": ctx.bin_dir.path}

    if not exit_code:
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
        env["JS_BINARY__EXIT_CODE_OUTPUT_FILE"] = exit_code.path

        ctx.actions.run(
            inputs = _gather_inputs(ctx, srcs),
            outputs = [report, exit_code],
            executable = executable._eslint,
            arguments = [args],
            env = env,
            mnemonic = _MNEMONIC,
        )

def eslint_fix(ctx, executable, srcs, patch, stdout, exit_code):
    """Create a Bazel Action that spawns eslint with --fix.

    Args:
        ctx: an action context OR aspect context
        executable: struct with an eslint field
        srcs: list of file objects to lint
        patch: output file containing the applied fixes that can be applied with the patch(1) command.
        stdout: output file containing the stdout or --output-file of eslint
        exit_code: output file containing the exit code of eslint
    """
    patch_cfg = ctx.actions.declare_file("_{}.patch_cfg".format(ctx.label.name))

    ctx.actions.write(
        output = patch_cfg,
        content = json.encode({
            "linter": executable._eslint.path,
            "args": ["--fix", "--format", "../../../" + ctx.file._formatter.path] + [s.short_path for s in srcs],
            "env": {"BAZEL_BINDIR": ctx.bin_dir.path},
            "files_to_diff": [s.path for s in srcs],
            "output": patch.path,
        }),
    )

    ctx.actions.run(
        inputs = _gather_inputs(ctx, srcs) + [patch_cfg],
        outputs = [patch, stdout, exit_code],
        executable = executable._patcher,
        arguments = [patch_cfg.path],
        env = {
            "BAZEL_BINDIR": ".",
            "JS_BINARY__EXIT_CODE_OUTPUT_FILE": exit_code.path,
            "JS_BINARY__STDOUT_OUTPUT_FILE": stdout.path,
            "JS_BINARY__SILENT_ON_SUCCESS": "1",
        },
        tools = [executable._eslint],
        mnemonic = _MNEMONIC,
    )

# buildifier: disable=function-docstring
def _eslint_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["js_library", "ts_project", "ts_project_rule"]:
        return []

    files_to_lint = filter_srcs(ctx.rule)
    if ctx.attr._options[LintOptionsInfo].fix:
        patch, report, exit_code, info = patch_and_report_files(_MNEMONIC, target, ctx)
        eslint_fix(ctx, ctx.executable, files_to_lint, patch, report, exit_code)
    else:
        report, exit_code, info = report_files(_MNEMONIC, target, ctx)
        eslint_action(ctx, ctx.executable, files_to_lint, report, exit_code)

    return [info]

def lint_eslint_aspect(binary, configs):
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
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
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
