"""Configures [qmllint](https://doc.qt.io/qt-6/qtqml-tooling-qmllint.html) to run as a Bazel aspect.

Typical usage:

Create an executable target for the PySide wrapper, for example in `tools/lint/BUILD.bazel`:

```starlark
load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

py_console_script_binary(
    name = "pyside6-qmllint",
    pkg = "@pip//pyside6_essentials:pkg",
    script = "pyside6-qmllint",
)
```

Then declare the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:qmllint.bzl", "lint_qmllint_aspect")

qmllint = lint_qmllint_aspect(
    binary = Label("//tools/lint:pyside6-qmllint"),
    config = Label("//:.qmllint.ini"),
)
```

Finally, opt QML sources into linting by tagging a `filegroup` with `qml`, or by
providing a custom `rule_kinds` list that matches your QML rules.
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "should_visit")
load("//lint/private:patcher_action.bzl", "patcher_attrs", "run_patcher")

_MNEMONIC = "AspectRulesLintQmllint"

def qmllint_action(ctx, executable, srcs, config, stdout, exit_code = None, patch = None):
    """Run qmllint as an action under Bazel.

    Args:
        ctx: The Bazel action context.
        executable: The qmllint executable to run.
        srcs: The source files to lint.
        config: A configuration file to pass to qmllint.
        stdout: The file to write the human-readable report to.
        exit_code: An optional file to write the exit code to. If not provided, the action will not capture the exit code.
        patch: output file for patch (optional). If provided, uses run_patcher instead of run_shell.
    """
    inputs = srcs + [config]

    if patch != None:
        wrapper = ctx.actions.declare_file(ctx.label.name + ".qmllint_wrapper.sh")
        args_list = [s.path for s in srcs]
        ctx.actions.write(
            output = wrapper,
            content = """#!/bin/bash
"{qmllint}" --fix "$@"
"{qmllint}" --max-warnings=0 "$@" 2>&1
""".format(qmllint = executable.path),
            is_executable = True,
        )

        run_patcher(
            ctx,
            ctx.executable,
            inputs = inputs,
            args = args_list,
            files_to_diff = [s.path for s in srcs],
            patch_out = patch,
            tools = [executable],
            stdout = stdout,
            exit_code = exit_code,
            mnemonic = _MNEMONIC,
            progress_message = "Fixing %{label} with qmllint",
        )
    else:
        outputs = [stdout]
        args = ctx.actions.args()
        args.add_all(srcs)
        args.add("--max-warnings=0") # Fail if any warnings are found

        if exit_code:
            command = "{qmllint} $@ > {stdout}; echo $? > {exit_code}".format(
                qmllint = executable.path,
                stdout = stdout.path,
                exit_code = exit_code.path,
            )
            outputs.append(exit_code)
        else:
            command = "{qmllint} $@ > {stdout} 2>&1".format(
                qmllint = executable.path,
                stdout = stdout.path,
            )

        ctx.actions.run_shell(
            inputs = inputs,
            outputs = outputs,
            arguments = [args],
            tools = [executable],
            command = command,
            mnemonic = _MNEMONIC,
            progress_message = "Linting %{label} with qmllint",
        )

# buildifier: disable=function-docstring
def _qmllint_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds, ctx.attr._filegroup_tags):
        return []

    files_to_lint = filter_srcs(ctx.rule)
    outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    qmllint_action(
        ctx,
        ctx.executable._qmllint,
        files_to_lint,
        ctx.file._config_file,
        outputs.human.out,
        outputs.human.exit_code,
        patch = getattr(outputs, "patch", None),
    )

    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    qmllint_action(
        ctx,
        ctx.executable._qmllint,
        files_to_lint,
        ctx.file._config_file,
        raw_machine_report,
        outputs.machine.exit_code,
        patch = getattr(outputs, "patch", None),
    )
    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)

    return [info]

def lint_qmllint_aspect(binary, config, rule_kinds = [], filegroup_tags = ["qml", "lint-with-qmllint"]):
    """Create a qmllint aspect."""

    return aspect(
        implementation = _qmllint_aspect_impl,
        attrs = patcher_attrs | {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_qmllint": attr.label(
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
        },
        toolchains = [OPTIONAL_SARIF_PARSER_TOOLCHAIN],
    )
