"""API for declaring a pyright lint aspect that visits py_library rules.

Typical usage:

```
load("@aspect_rules_lint//lint:pyright.bzl", "pyright_aspect")

pyright = pyright_aspect(
    binary = "@@//:pyright",
    configs = "@@//:.pyright.toml",
)
```
"""

load("//lint/private:lint_aspect.bzl", "report_file")

_MNEMONIC = "pyright"

def pyright_action(ctx, executable, srcs, config, report):
    """Run pyright as an action under Bazel.

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the pyright program
        srcs: python files to be linted
        config: label of pyright config file
        report: output file to generate
    """

    inputs = srcs + [config]
    outputs = [report]
    args = ctx.actions.args()
    args.add_all(srcs)
    args.add_all(["--project", config])
    ctx.actions.run(
        inputs = inputs,
        outputs = outputs,
        executable = executable,
        arguments = [args],
        mnemonic = _MNEMONIC,
    )

# buildifier: disable=function-docstring
def _pyright_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["py_binary", "py_library"]:
        return []

    report, info = report_file(_MNEMONIC, target, ctx)

    # TODO: ctx.attr.fail_on_violation
    pyright_action(ctx, ctx.executable._pyright, ctx.rule.files.srcs, ctx.file._config_file, report)
    return [info]

def pyright_aspect(binary, config):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a pyright executable
        config: pyright config file, pyrightconfig.json or pyproject.toml
    """
    return aspect(
        implementation = _pyright_aspect_impl,
        # Edges we need to walk up the graph from the selected targets.
        # Needed for linters that need semantic information like transitive type declarations.
        # attr_aspects = ["deps"],
        attrs = {
            "fail_on_violation": attr.bool(),
            "_pyright": attr.label(
                default = binary,
                allow_single_file = True,
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(
                default = config,
                allow_single_file = True,
            ),
        },
    )
