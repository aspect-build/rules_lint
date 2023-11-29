"""API for declaring a Ruff lint aspect that visits py_library rules.

Typical usage:

```
load("@aspect_rules_lint//lint:ruff.bzl", "ruff_aspect")

ruff = ruff_aspect(
    binary = "@@//:ruff",
    configs = "@@//:.ruff.toml",
)
```
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//lint/private:lint_aspect.bzl", "report_file")
load(":ruff_versions.bzl", "RUFF_VERSIONS")

_MNEMONIC = "ruff"

def ruff_action(ctx, executable, srcs, config, report, use_exit_code = False):
    """Run ruff as an action under Bazel.

    Ruff will select the configuration file to use for each source file, as documented here:
    https://docs.astral.sh/ruff/configuration/#config-file-discovery

    Note: all config files are passed to the action.
    This means that a change to any config file invalidates the action cache entries for ALL
    ruff actions.

    However this is needed because:

    1. ruff has an `extend` field, so it may need to read more than one config file
    2. ruff's logic for selecting the appropriate config needs to read the file content to detect
      a `[tool.ruff]` section.

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the ruff program
        srcs: python files to be linted
        config: labels of ruff config files (pyproject.toml, ruff.toml, or .ruff.toml)
        report: output file to generate
        use_exit_code: whether to fail the build when a lint violation is reported
    """
    inputs = srcs + config
    outputs = [report]

    # Wire command-line options, see
    # `ruff help check` to see available options
    args = ctx.actions.args()
    args.add("check")
    args.add(report, format = "--output-file=%s")
    if not use_exit_code:
        args.add("--exit-zero")

    args.add_all(srcs)

    ctx.actions.run(
        inputs = inputs,
        outputs = outputs,
        executable = executable,
        arguments = [args],
        mnemonic = _MNEMONIC,
    )

# buildifier: disable=function-docstring
def _ruff_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["py_binary", "py_library"]:
        return []

    report, info = report_file(_MNEMONIC, target, ctx)
    ruff_action(ctx, ctx.executable._ruff, ctx.rule.files.srcs, ctx.files._config_files, report, ctx.attr.fail_on_violation)
    return [info]

def ruff_aspect(binary, configs):
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

        configs: ruff config file(s) (`pyproject.toml`, `ruff.toml`, or `.ruff.toml`)
    """

    # syntax-sugar: allow a single config file in addition to a list
    if type(configs) == "string":
        configs = [configs]

    return aspect(
        implementation = _ruff_aspect_impl,
        # Edges we need to walk up the graph from the selected targets.
        # Needed for linters that need semantic information like transitive type declarations.
        # attr_aspects = ["deps"],
        attrs = {
            "fail_on_violation": attr.bool(),
            "_ruff": attr.label(
                default = binary,
                allow_single_file = True,
                executable = True,
                cfg = "exec",
            ),
            "_config_files": attr.label_list(
                default = configs,
                allow_files = True,
            ),
        },
    )

def fetch_ruff(version = RUFF_VERSIONS.keys()[0]):
    """A repository macro used from WORKSPACE to fetch ruff binaries

    Args:
        version: a version of ruff that we have mirrored, e.g. `v0.1.0`
    """
    for plat, sha256 in RUFF_VERSIONS[version].items():
        maybe(
            http_archive,
            name = "ruff_" + plat,
            url = "https://github.com/astral-sh/ruff/releases/download/{tag}/ruff-{plat}.tar.gz".format(
                tag = version,
                plat = plat,
            ),
            sha256 = sha256,
            build_file_content = """exports_files(["ruff"])""",
        )
