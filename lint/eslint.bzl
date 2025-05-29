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
load("@aspect_rules_lint//lint:eslint.bzl", "lint_eslint_aspect")

eslint = lint_eslint_aspect(
    binary = Label("//tools/lint:eslint"),
    # We trust that eslint will locate the correct configuration file for a given source file.
    # See https://eslint.org/docs/latest/use/configure/configuration-files#cascading-and-hierarchy
    configs = [
        Label("//:eslintrc"),
        ...
    ],
)
```

### With ts_project <=3.2.0

Prior to [commit 5e25e91]https://github.com/aspect-build/rules_ts/commit/5e25e91420947e3a81938d8eb076803e5cf51fe2)
the rule produced by the `ts_project` macro and a custom `transpiler` expanded the macro to
multiple targets, including changing the default target to `js_library`.

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
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "patch_and_output_files", "should_visit")

_MNEMONIC = "AspectRulesLintESLint"

def _gather_inputs(ctx, srcs, files):
    inputs = copy_files_to_bin_actions(ctx, srcs)

    # Add the config file along with any deps it has on npm packages
    if "gather_files_from_js_providers" in dir(js_lib_helpers):
        # rules_js 1.x
        js_inputs = js_lib_helpers.gather_files_from_js_providers(
            ctx.attr._config_files + ctx.rule.attr.deps + files,
            include_transitive_sources = True,
            include_declarations = True,
            include_npm_linked_packages = True,
        )
    else:
        # rules_js 2.x
        js_inputs = js_lib_helpers.gather_files_from_js_infos(
            ctx.attr._config_files + ctx.rule.attr.deps + files,
            include_sources = True,
            include_transitive_sources = True,
            include_types = True,
            include_transitive_types = True,
            include_npm_sources = True,
        )
    return depset(inputs, transitive = [js_inputs])

def eslint_action(ctx, executable, srcs, stdout, exit_code = None, format = "stylish", env = {}):
    """Create a Bazel Action that spawns an eslint process.

    Adapter for wrapping Bazel around
    https://eslint.org/docs/latest/use/command-line-interface

    Args:
        ctx: an action context OR aspect context
        executable: struct with an eslint field
        srcs: list of file objects to lint
        stdout: output file containing the stdout or --output-file of eslint
        exit_code: output file containing the exit code of eslint.
            If None, then fail the build when eslint exits non-zero.
        format: value for eslint `--format` CLI flag
        env: environment variables for eslint
    """

    args = ctx.actions.args()
    args.add("--no-warn-ignored")
    file_inputs = [ctx.attr._workaround_17660]

    if ctx.attr._options[LintOptionsInfo].debug:
        args.add("--debug")
    if type(format) == "string":
        args.add_all(["--format", format])
    else:
        args.add_all(["--format", "../../../" + format.files.to_list()[0].path])
        file_inputs.append(format)
    args.add_all([s.short_path for s in srcs])

    if not exit_code:
        ctx.actions.run_shell(
            inputs = _gather_inputs(ctx, srcs, file_inputs),
            outputs = [stdout],
            tools = [executable._eslint],
            arguments = [args],
            command = executable._eslint.path + " $@ && touch " + stdout.path,
            env = dict(env, **{
                "BAZEL_BINDIR": ctx.bin_dir.path,
            }),
            mnemonic = _MNEMONIC,
            progress_message = "Linting %{label} with ESLint",
        )
    else:
        # Workaround: create an empty file in case eslint doesn't write one
        # Use `../../..` to return to the execroot?
        args.add_joined(["--node_options", "--require", "../../../" + ctx.file._workaround_17660.path], join_with = "=")

        args.add_all(["--output-file", stdout.short_path])

        ctx.actions.run(
            inputs = _gather_inputs(ctx, srcs, file_inputs),
            outputs = [stdout, exit_code],
            executable = executable._eslint,
            arguments = [args],
            env = dict(env, **{
                "BAZEL_BINDIR": ctx.bin_dir.path,
                "JS_BINARY__EXIT_CODE_OUTPUT_FILE": exit_code.path,
            }),
            mnemonic = _MNEMONIC,
            progress_message = "Linting %{label} with ESLint",
        )

def eslint_fix(ctx, executable, srcs, patch, stdout, exit_code, format = "stylish", env = {}):
    """Create a Bazel Action that spawns eslint with --fix.

    Args:
        ctx: an action context OR aspect context
        executable: struct with an eslint field
        srcs: list of file objects to lint
        patch: output file containing the applied fixes that can be applied with the patch(1) command.
        stdout: output file containing the stdout or --output-file of eslint
        exit_code: output file containing the exit code of eslint
        format: value for eslint `--format` CLI flag
        env: environment variaables for eslint
    """
    patch_cfg = ctx.actions.declare_file("_{}.patch_cfg".format(ctx.label.name))

    file_inputs = [ctx.attr._workaround_17660]
    args = ["--fix"]

    if type(format) == "string":
        args.extend(["--format", format])
    else:
        args.extend(["--format", "../../../" + format.files.to_list()[0].path])
        file_inputs.append(format)
    args.extend([s.short_path for s in srcs])

    ctx.actions.write(
        output = patch_cfg,
        content = json.encode({
            "linter": executable._eslint.path,
            "args": args,
            "env": dict(env, **{"BAZEL_BINDIR": ctx.bin_dir.path}),
            "files_to_diff": [s.path for s in srcs],
            "output": patch.path,
        }),
    )

    ctx.actions.run(
        inputs = depset([patch_cfg], transitive = [_gather_inputs(ctx, srcs, file_inputs)]),
        outputs = [patch, stdout, exit_code],
        executable = executable._patcher,
        arguments = [patch_cfg.path],
        env = dict(env, **{
            "BAZEL_BINDIR": ".",
            "JS_BINARY__EXIT_CODE_OUTPUT_FILE": exit_code.path,
            "JS_BINARY__STDOUT_OUTPUT_FILE": stdout.path,
            "JS_BINARY__SILENT_ON_SUCCESS": "1",
        }),
        tools = [executable._eslint],
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with ESLint",
    )

# buildifier: disable=function-docstring
def _eslint_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []

    files_to_lint = filter_srcs(ctx.rule)
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    # https://www.npmjs.com/package/chalk#chalklevel
    # 2: Force 256 color support even when a tty isn't detected
    color_env = {"FORCE_COLOR": "2"} if ctx.attr._options[LintOptionsInfo].color else {}

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    # eslint can produce a patch file at the same time it reports the unpatched violations
    if hasattr(outputs, "patch"):
        eslint_fix(ctx, ctx.executable, files_to_lint, outputs.patch, outputs.human.out, outputs.human.exit_code, format = ctx.attr._stylish_formatter, env = color_env)
    else:
        eslint_action(ctx, ctx.executable, files_to_lint, outputs.human.out, outputs.human.exit_code, format = ctx.attr._stylish_formatter, env = color_env)

    # TODO(alex): if we run with --fix, this will report the issues that were fixed. Does a machine reader want to know about them?
    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    eslint_action(ctx, ctx.executable, files_to_lint, raw_machine_report, outputs.machine.exit_code, format = ctx.attr._compact_formatter)

    # We could probably use https://www.npmjs.com/package/@microsoft/eslint-formatter-sarif instead.
    # However it probably requires the user to install this and pass it to us.
    # Also we always have the problem of getting execroot-relative paths
    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)

    return [info]

def lint_eslint_aspect(binary, configs, rule_kinds = ["js_library", "ts_project", "ts_project_rule"]):
    """A factory function to create a linter aspect.

    Args:
        binary: the eslint binary, typically a rule like

            ```
            load("@npm//:eslint/package_json.bzl", eslint_bin = "bin")
            eslint_bin.eslint_binary(name = "eslint")
            ```
        configs: label(s) of the eslint config file(s)
        rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect
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
            "_compact_formatter": attr.label(
                default = "@aspect_rules_lint//lint:eslint.compact-formatter",
                allow_single_file = True,
                cfg = "exec",
            ),
            "_stylish_formatter": attr.label(
                default = "@aspect_rules_lint//lint:eslint.stylish-formatter",
                allow_single_file = True,
                cfg = "exec",
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
        toolchains = COPY_FILE_TO_BIN_TOOLCHAINS + [OPTIONAL_SARIF_PARSER_TOOLCHAIN],
    )
