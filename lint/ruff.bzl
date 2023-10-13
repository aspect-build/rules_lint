"""API for declaring a Ruff lint aspect that visits py_library rules.

Typical usage:

```
load("@aspect_rules_lint//lint:ruff.bzl", "ruff_aspect")

ruff = ruff_aspect(
    binary = "@@//:ruff",
    config = "@@//:.ruff.toml",
)
```
"""

def ruff_action(ctx, executable, srcs, config, report, use_exit_code = False):
    """Run ruff as an action under Bazel.

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the ruff program
        srcs: python files to be linted
        config: label of the ruff config file (pyproject.toml, ruff.toml, or .ruff.toml)
        report: output file to generate
        use_exit_code: whether to fail the build when a lint violation is reported
    """
    inputs = srcs + [config]
    outputs = [report]

    # Wire command-line options, see
    # `ruff help check` to see available options
    args = ctx.actions.args()
    args.add("check")
    args.add(config, format = "--config=%s")
    if not use_exit_code:
        args.add("--exit-zero")

    args.add_all(srcs)

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        tools = [executable],
        command = "%s $@ > %s" % (executable.path, report.path),
        arguments = [args],
        mnemonic = "ruff",
    )

# buildifier: disable=function-docstring
def _ruff_aspect_impl(target, ctx):
    if ctx.rule.kind in ["py_library"]:
        report = ctx.actions.declare_file(target.label.name + ".ruff-report.txt")
        ruff_action(ctx, ctx.executable._ruff, ctx.rule.files.srcs, ctx.file._config_file, report)
        results = depset([report])
    else:
        results = depset()

    return [
        OutputGroupInfo(report = results),
    ]

def ruff_aspect(binary, config):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a ruff executable. Can be obtained like so:

            load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

            http_archive(
                name = "ruff_bin_linux_amd64",
                sha256 = "<-sha->",
                urls = [
                    "https://github.com/charliermarsh/ruff/releases/download/v<-version->/ruff-x86_64-unknown-linux-gnu.tar.gz",
                ],
                build_file_content = \"""exports_files(["ruff"])\""",
            )

        config: the ruff config file (`pyproject.toml`, `ruff.toml`, or `.ruff.toml`)
    """
    return aspect(
        implementation = _ruff_aspect_impl,
        # Edges we need to walk up the graph from the selected targets.
        # Needed for linters that need semantic information like transitive type declarations.
        # attr_aspects = ["deps"],
        attrs = {
            "_ruff": attr.label(
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

