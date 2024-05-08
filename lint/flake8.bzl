"""API for declaring a flake8 lint aspect that visits py_library rules.

Typical usage:

First, fetch the flake8 package via your standard requirements file and pip calls.

Then, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")
py_console_script_binary(
    name = "flake8",
    pkg = "@pip//flake8:pkg",
)
```

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:flake8.bzl", "lint_flake8_aspect")

flake8 = lint_flake8_aspect(
    binary = "@@//tools/lint:flake8",
    config = "@@//:.flake8",
)
```
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "report_file")

_MNEMONIC = "flake8"

def flake8_action(ctx, executable, srcs, config, stdout, exit_code = None):
    """Run flake8 as an action under Bazel.

    Based on https://flake8.pycqa.org/en/latest/user/invocation.html

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the flake8 program
        srcs: python files to be linted
        config: label of the flake8 config file (setup.cfg, tox.ini, or .flake8)
        stdout: output file containing stdout of flake8
        exit_code: output file containing exit code of flake8
            If None, then fail the build when flake8 exits non-zero.
    """
    inputs = srcs + [config]
    outputs = [stdout]

    # Wire command-line options, see
    # https://flake8.pycqa.org/en/latest/user/options.html
    args = ctx.actions.args()
    args.add_all(srcs)
    args.add(config, format = "--config=%s")

    if exit_code:
        command = "{flake8} $@ >{stdout}; echo $? > " + exit_code.path
        outputs.append(exit_code)
    else:
        # Create empty stdout file on success, as Bazel expects one
        command = "{flake8} $@ && touch {stdout}"

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        tools = [executable],
        command = command.format(flake8 = executable.path, stdout = stdout.path),
        arguments = [args],
        mnemonic = _MNEMONIC,
    )

# buildifier: disable=function-docstring
def _flake8_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["py_binary", "py_library"]:
        return []

    report, exit_code, info = report_file(_MNEMONIC, target, ctx)
    flake8_action(ctx, ctx.executable._flake8, filter_srcs(ctx.rule), ctx.file._config_file, report, exit_code)
    return [info]

def lint_flake8_aspect(binary, config):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a flake8 executable. Can be obtained from rules_python like so:

            load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

            py_console_script_binary(
                name = "flake8",
                pkg = "@pip//flake8:pkg",
            )

        config: the flake8 config file (`setup.cfg`, `tox.ini`, or `.flake8`)
    """
    return aspect(
        implementation = _flake8_aspect_impl,
        # Edges we need to walk up the graph from the selected targets.
        # Needed for linters that need semantic information like transitive type declarations.
        # attr_aspects = ["deps"],
        attrs = {
            "_options": attr.label(
                default = "//lint:fail_on_violation",
                providers = [LintOptionsInfo],
            ),
            "_flake8": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(
                default = config,
                allow_single_file = True,
            ),
        },
    )
