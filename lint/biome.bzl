"""API for declaring a Biome lint aspect.

Typical usage:

First, install Biome using your typical npm package.json and rules_js rules.

Next, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
load("@npm//:@biomejs/biome/package_json.bzl", biome_bin = "bin")
biome_bin.biome_binary(name = "biome")
```

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:biome.bzl", "lint_biome_aspect")

biome = lint_biome_aspect(
    binary = Label("//tools/lint:biome"),
    configs = [Label("//:biomeconfig")],
)
```
"""

load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("//lint/private:js_linter_inputs.bzl", "COPY_FILE_TO_BIN_TOOLCHAINS", "copy_or_reuse_bin_inputs")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "patch_and_output_files", "should_visit")
load("//lint/private:patcher_action.bzl", "patcher_attrs", "run_patcher")

_MNEMONIC = "AspectRulesLintBiome"

def _config_options(config_files):
    if len(config_files) > 1:
        fail("Biome accepts a single config file or directory, got {}".format(config_files))
    if len(config_files) == 0:
        return []
    return ["--config-path={}".format(config_files[0].path)]

def _gather_inputs(ctx, target, srcs):
    copied_srcs = copy_or_reuse_bin_inputs(ctx, target, srcs)

    js_inputs = ctx.attr._config_files + getattr(ctx.rule.attr, "deps", [])

    if hasattr(ctx.rule.attr, "tsconfig"):
        js_inputs.append(ctx.rule.attr.tsconfig)

    if "gather_files_from_js_providers" in dir(js_lib_helpers):
        js_inputs = js_lib_helpers.gather_files_from_js_providers(
            js_inputs,
            include_transitive_sources = True,
            include_declarations = True,
            include_npm_linked_packages = True,
        )
    else:
        js_inputs = js_lib_helpers.gather_files_from_js_infos(
            js_inputs,
            include_sources = True,
            include_transitive_sources = True,
            include_types = True,
            include_transitive_types = True,
            include_npm_sources = True,
        )
    return struct(
        inputs = depset(srcs + copied_srcs + ctx.files._config_files, transitive = [js_inputs]),
        srcs = copied_srcs,
    )

def _source_paths(srcs, copied_srcs):
    paths = []
    for i, src in enumerate(srcs):
        if src.is_source and src.owner.workspace_name == "":
            paths.append(src.path)
        else:
            paths.append(copied_srcs[i].path)
    return paths

def biome_action(ctx, executable, srcs, stdout, exit_code = None, options = [], env = {}, patch = None, target = None):
    """Spawn Biome as a Bazel action.

    Args:
        ctx: an action context OR aspect context
        executable: struct with a _biome field
        srcs: list of file objects to lint
        stdout: output file containing stdout
        exit_code: output file containing the exit code.
            If None, then fail the build when Biome exits non-zero.
        options: additional command-line arguments
        env: environment variables for Biome
        patch: output file for patch (optional). If provided, uses run_patcher.
        target: the aspect target, used to reuse bin-tree inputs already produced by the target
    """
    gathered_inputs = _gather_inputs(ctx, target, srcs)
    src_paths = _source_paths(srcs, gathered_inputs.srcs)
    config_options = _config_options(ctx.files._config_files)
    args_list = ["lint"] + config_options + list(options) + src_paths

    if patch != None:
        run_patcher(
            ctx,
            executable,
            inputs = gathered_inputs.inputs,
            args = ["lint", "--write"] + config_options + list(options) + src_paths,
            files_to_diff = src_paths,
            patch_out = patch,
            tools = [executable._biome],
            patch_cfg_env = dict(env, **{"BAZEL_BINDIR": ctx.bin_dir.path}),
            stdout = stdout,
            exit_code = exit_code,
            env = env,
            mnemonic = _MNEMONIC,
            progress_message = "Linting %{label} with Biome",
            patch_cfg_name = "{}.{}".format(ctx.label.name, _MNEMONIC),
        )
        return

    outputs = [stdout]
    if exit_code:
        outputs.append(exit_code)

    args = ctx.actions.args()
    args.add_all(args_list)

    if exit_code:
        command = "{biome} $@ >{stdout}; echo $? >{exit_code}"
    else:
        command = "{biome} $@ && touch {stdout}"

    ctx.actions.run_shell(
        inputs = gathered_inputs.inputs,
        outputs = outputs,
        tools = [executable._biome],
        arguments = [args],
        command = command.format(
            biome = executable._biome.path,
            stdout = stdout.path,
            exit_code = exit_code.path if exit_code else "",
        ),
        env = dict(env, **{
            "BAZEL_BINDIR": ctx.bin_dir.path,
        }),
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with Biome",
    )

# buildifier: disable=function-docstring
def _biome_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []

    files_to_lint = filter_srcs(ctx.rule)
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    color_options = ["--colors=force"] if ctx.attr._options[LintOptionsInfo].color else ["--colors=off"]

    biome_action(
        ctx,
        ctx.executable,
        files_to_lint,
        outputs.human.out,
        outputs.human.exit_code,
        options = color_options,
        patch = getattr(outputs, "patch", None),
        target = target,
    )

    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    biome_action(
        ctx,
        ctx.executable,
        files_to_lint,
        raw_machine_report,
        outputs.machine.exit_code,
        options = ["--colors=off", "--reporter=sarif"],
        target = target,
    )
    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)

    return [info]

def lint_biome_aspect(binary, configs = [], rule_kinds = ["js_library", "ts_project", "ts_project_rule"]):
    """A factory function to create a Biome lint aspect.

    Args:
        binary: the Biome binary, typically a rule like

            ```
            load("@npm//:@biomejs/biome/package_json.bzl", biome_bin = "bin")
            biome_bin.biome_binary(name = "biome")
            ```

        configs: label(s) of Biome config files
        rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect
    """

    if type(configs) == "string":
        configs = [configs]
    return aspect(
        implementation = _biome_aspect_impl,
        attrs = patcher_attrs | {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_biome": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config_files": attr.label_list(
                default = configs,
                allow_files = True,
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
        toolchains = COPY_FILE_TO_BIN_TOOLCHAINS + [OPTIONAL_SARIF_PARSER_TOOLCHAIN],
    )
