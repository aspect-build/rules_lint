"""Configures [yamllint](https://yamllint.readthedocs.io/) to run as a Bazel aspect.

Typical usage:

Create an executable target for yamllint, for example in `tools/lint/BUILD.bazel`:

```starlark
load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

py_console_script_binary(
    name = "yamllint",
    pkg = "@pip//yamllint:pkg",
)
```

Then declare the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:yamllint.bzl", "lint_yamllint_aspect")

yamllint = lint_yamllint_aspect(
    binary = Label("//tools/lint:yamllint"),
    config = Label("//:.yamllint"),
)
```

Finally, opt YAML sources into linting by tagging a `filegroup` with `lint-with-yamllint`, or by
providing a custom `rule_kinds` list that matches your YAML rules.
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "should_visit")

_MNEMONIC = "AspectRulesLintYamllint"

_YAML_EXTENSIONS = (".yaml", ".yml")

def yamllint_action(ctx, executable, srcs, config, stdout, exit_code = None, format = None, options = []):
    """Run yamllint as an action under Bazel.

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: File representing the yamllint program
        srcs: YAML files to lint
        config: yamllint configuration file
        stdout: output file for yamllint stdout
        exit_code: optional output file for exit code. If absent, non-zero exits fail the build.
        format: optional formatter passed via `-f`
        options: additional command-line options
    """
    inputs = list(srcs)
    if config:
        inputs.append(config)

    args = ctx.actions.args()
    if format:
        args.add_all(["-f", format])
    args.add_all(options)
    if config:
        args.add("-c")
        args.add(config.path)
    args.add_all(srcs)

    outputs = [stdout]
    if exit_code:
        command = "{yamllint} $@ >{stdout}; echo $? > {exit_code}".format(
            yamllint = executable.path,
            stdout = stdout.path,
            exit_code = exit_code.path,
        )
        outputs.append(exit_code)
    else:
        command = "{yamllint} $@ && touch {stdout}".format(
            yamllint = executable.path,
            stdout = stdout.path,
        )

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        arguments = [args],
        tools = [executable],
        command = command,
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with yamllint",
    )

def _yaml_files(files):
    return [f for f in files if f.basename.endswith(_YAML_EXTENSIONS)]

# buildifier: disable=function-docstring
def _yamllint_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds, ctx.attr._filegroup_tags):
        return []

    files_to_lint = _yaml_files(filter_srcs(ctx.rule))
    outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    color_format = "colored" if ctx.attr._options[LintOptionsInfo].color else "standard"
    common_options = ctx.attr._extra_args
    yamllint_action(
        ctx,
        ctx.executable._yamllint,
        files_to_lint,
        ctx.file._config_file,
        outputs.human.out,
        outputs.human.exit_code,
        format = color_format,
        options = common_options,
    )

    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    yamllint_action(
        ctx,
        ctx.executable._yamllint,
        files_to_lint,
        ctx.file._config_file,
        raw_machine_report,
        outputs.machine.exit_code,
        format = "parsable",
        options = common_options,
    )
    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)
    return [info]

def lint_yamllint_aspect(
        binary,
        config,
        rule_kinds = ["yaml_library"],
        filegroup_tags = ["lint-with-yamllint"],
        extra_args = []):
    """Create a yamllint aspect."""
    attrs = {
        "_options": attr.label(
            default = "//lint:options",
            providers = [LintOptionsInfo],
        ),
        "_yamllint": attr.label(
            default = binary,
            executable = True,
            cfg = "exec",
        ),
        "_config_file": attr.label(
            default = config,
            allow_single_file = True,
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
    }

    return aspect(
        implementation = _yamllint_aspect_impl,
        attrs = attrs,
        toolchains = [OPTIONAL_SARIF_PARSER_TOOLCHAIN],
    )
