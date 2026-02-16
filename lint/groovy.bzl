"""API for declaring a npm-groovy-lint aspect that visits filegroups tagged with "groovy".

Configure the groovy lint binary (can be obtained via rules_js):
```starlark
load("@npm//:npm-groovy-lint/package_json.bzl", groovy_bin = "bin")

groovy_bin.npm_groovy_lint_binary(
    name = "groovy-lint",
    data = ["//:.groovylintrc.json"],
    env = {"BAZEL_BINDIR": "."},
    fixed_args = [
        "--config=\"$$JS_BINARY__RUNFILES\"/$(rlocationpath //:.groovylintrc.json)",
    ],
)
```

Create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:groovy.bzl", "lint_groovy_aspect")

groovy = lint_groovy_aspect(
    binary = Label("//tools/lint:groovy-lint"),
    config = Label("//:.groovylintrc.json"),
)
```

Then create a filegroup for your Groovy files with the "groovy" tag:

```starlark
filegroup(
    name = "groovy_files",
    srcs = glob(["**/*.groovy"]),
    tags = ["groovy"],
)
```
"""

load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "noop_lint_action", "output_files", "patch_and_output_files", "should_visit")
load("//lint/private:patcher_action.bzl", "patcher_attrs", "run_patcher")

_MNEMONIC = "AspectRulesLintGroovy"

def _gather_inputs(ctx, srcs, config):
    inputs = list(srcs) + [config]

    js_inputs = js_lib_helpers.gather_files_from_js_infos(
        [ctx.attr._groovy_lint],
        include_sources = True,
        include_transitive_sources = True,
        include_types = True,
        include_transitive_types = True,
        include_npm_sources = True,
    )
    return depset(inputs, transitive = [js_inputs])

def groovy_action(ctx, executable, srcs, config, stdout, exit_code = None, format = "txt", env = {}, patch = None):
    """Create a Bazel Action that spawns an npm-groovy-lint process.

    Adapter for wrapping Bazel around
    https://github.com/nvuillam/npm-groovy-lint

    Args:
        ctx: an action context OR aspect context
        executable: label of the npm-groovy-lint binary
        srcs: list of groovy files to lint
        config: a npm-groovy-lint config file
        stdout: output file containing the stdout of npm-groovy-lint
        exit_code: output file containing the exit code.
        format: output format ("txt", "sarif", "json", "html", "xml")
        env: environment variables for npm-groovy-lint
        patch: output file for patch (optional). If provided, uses run_patcher instead of run_shell.
    """
    inputs = _gather_inputs(ctx, srcs, config)

    if patch != None:
        # Fix mode: use run_patcher
        args_list = [
            "--noserver",
            "--fix",
            "--failon", "error",
            "--config", config.path,
            "--output", format,
        ] + [s.path for s in srcs]

        run_patcher(
            ctx,
            executable,
            inputs = inputs,
            args = args_list,
            files_to_diff = [s.path for s in srcs],
            patch_out = patch,
            tools = [executable._groovy_lint],
            stdout = stdout,
            exit_code = exit_code,
            env = env,
            mnemonic = _MNEMONIC,
            progress_message = "Fixing %{label} with npm-groovy-lint",
        )
    else:
        # Lint mode: use run_shell
        # Use --output with a file path so npm-groovy-lint writes directly to a
        # file. This prevents JRE download messages from polluting the report.
        # npm-groovy-lint infers the output format from the file extension, so we
        # write to a temp path with the correct extension then move it.
        outputs = [stdout]
        tmp_out = stdout.path + "." + format

        # npm-groovy-lint needs --noserver in bazel sandbox as it can't persist the server
        if exit_code:
            command = "{lint} --noserver --failon error --config {config} --output {tmp_out} {srcs}; echo $? > {exit_code}; if [ -f {tmp_out} ]; then mv {tmp_out} {out}; else touch {out}; fi".format(
                lint = executable._groovy_lint.path,
                config = config.path,
                tmp_out = tmp_out,
                out = stdout.path,
                exit_code = exit_code.path,
                srcs = " ".join([s.path for s in srcs]),
            )
            outputs.append(exit_code)
        else:
            command = "{lint} --noserver --failon error --config {config} --output {tmp_out} {srcs}; LINT_EXIT=$?; if [ -f {tmp_out} ]; then mv {tmp_out} {out}; else touch {out}; fi; exit $LINT_EXIT".format(
                lint = executable._groovy_lint.path,
                config = config.path,
                tmp_out = tmp_out,
                out = stdout.path,
                srcs = " ".join([s.path for s in srcs]),
            )

        ctx.actions.run_shell(
            command = command,
            inputs = inputs,
            outputs = outputs,
            tools = [executable._groovy_lint],
            mnemonic = _MNEMONIC,
            env = dict(env, **{"BAZEL_BINDIR": "."}),
            progress_message = "Linting %{label} with npm-groovy-lint (" + format + ")",
        )

def _groovy_aspect_impl(target, ctx):
    if "no-groovy-lint" in ctx.rule.attr.tags:
        return []

    if not should_visit(ctx.rule, ctx.attr._rule_kinds, ctx.attr._filegroup_tags):
        return []

    groovy_files = [f for f in filter_srcs(ctx.rule) if f.extension == "groovy"]

    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    if not groovy_files:
        noop_lint_action(ctx, outputs)
        return [info]

    config = ctx.file._config

    # Human-readable output (txt format)
    groovy_action(
        ctx,
        ctx.executable,
        groovy_files,
        config,
        outputs.human.out,
        outputs.human.exit_code,
        format = "txt",
        patch = getattr(outputs, "patch", None),
    )

    # Machine-readable output (sarif format)
    groovy_action(
        ctx,
        ctx.executable,
        groovy_files,
        config,
        outputs.machine.out,
        outputs.machine.exit_code,
        format = "sarif",
    )

    return [info]

def lint_groovy_aspect(binary, config, rule_kinds = [], filegroup_tags = ["groovy", "lint-with-groovy"]):
    """A factory function to create a linter aspect for Groovy files.

    Args:
        binary: the npm-groovy-lint binary, typically a rule like

            ```
            load("@npm//:npm-groovy-lint/package_json.bzl", groovy_bin = "bin")
            groovy_bin.npm_groovy_lint_binary(name = "groovy-lint")
            ```
        config: label of the .groovylintrc.json config file
        rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect
        filegroup_tags: filegroups tagged with these tags will be visited by the aspect
    """
    return aspect(
        implementation = _groovy_aspect_impl,
        attr_aspects = ["deps"],
        attrs = patcher_attrs | {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_groovy_lint": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config": attr.label(
                default = config,
                allow_single_file = True,
            ),
            "_filegroup_tags": attr.string_list(
                default = filegroup_tags,
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
    )
