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

load("@bazel_skylib//lib:versions.bzl", "versions")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "patch_and_report_files")
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
    args.add_all(srcs)

    if use_exit_code:
        ctx.actions.run_shell(
            inputs = inputs,
            outputs = outputs,
            command = executable.path + " $@ && touch " + report.path,
            arguments = [args],
            mnemonic = _MNEMONIC,
            tools = [executable],
        )
    else:
        args.add(report, format = "--output-file=%s")
        args.add("--exit-zero")

        ctx.actions.run(
            inputs = inputs,
            outputs = outputs,
            executable = executable,
            arguments = [args],
            mnemonic = _MNEMONIC,
        )

def ruff_fix(ctx, executable, srcs, config, patch):
    """Create a Bazel Action that spawns ruff with --fix.

    Args:
        ctx: an action context OR aspect context
        executable: struct with _ruff and _patcher field
        srcs: list of file objects to lint
        config: labels of ruff config files (pyproject.toml, ruff.toml, or .ruff.toml)
        patch: output file containing the applied fixes that can be applied with the patch(1) command.
    """
    patch_cfg = ctx.actions.declare_file("_{}.patch_cfg".format(ctx.label.name))

    ctx.actions.write(
        output = patch_cfg,
        content = json.encode({
            "linter": executable._ruff.path,
            "args": ["check", "--fix"] + [s.path for s in srcs],
            "files_to_diff": [s.path for s in srcs],
            "output": patch.path,
        }),
    )

    ctx.actions.run(
        inputs = srcs + config + [patch_cfg],
        outputs = [patch],
        executable = executable._patcher,
        arguments = [patch_cfg.path],
        env = {"BAZEL_BINDIR": "."},
        tools = [executable._ruff],
        mnemonic = _MNEMONIC,
    )

# buildifier: disable=function-docstring
def _ruff_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["py_binary", "py_library", "py_test"]:
        return []

    patch, report, info = patch_and_report_files(_MNEMONIC, target, ctx)
    files_to_lint = filter_srcs(ctx.rule)
    ruff_action(ctx, ctx.executable._ruff, files_to_lint, ctx.files._config_files, report, ctx.attr._options[LintOptionsInfo].fail_on_violation)
    ruff_fix(ctx, ctx.executable, files_to_lint, ctx.files._config_files, patch)
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
            "_options": attr.label(
                default = "//lint:fail_on_violation",
                providers = [LintOptionsInfo],
            ),
            "_ruff": attr.label(
                default = binary,
                allow_single_file = True,
                executable = True,
                cfg = "exec",
            ),
            "_patcher": attr.label(
                default = "@aspect_rules_lint//lint/private:patcher",
                executable = True,
                cfg = "exec",
            ),
            "_config_files": attr.label_list(
                default = configs,
                allow_files = True,
            ),
        },
    )

def _ruff_workaround_20269_impl(rctx):
    # download_and_extract has a bug due to the use of Apache Commons library within Bazel,
    # see https://issues.apache.org/jira/projects/COMPRESS/issues/COMPRESS-654
    # To workaround, we fetch the file and then use the BSD tar on the system to extract it.
    rctx.download(sha256 = rctx.attr.sha256, url = rctx.attr.url, output = "ruff.tar.gz")
    result = rctx.execute([rctx.which("tar"), "xzf", "ruff.tar.gz"])
    if result.return_code:
        fail("Couldn't extract ruff: \nSTDOUT:\n{}\nSTDERR:\n{}".format(result.stdout, result.stderr))
    rctx.file("BUILD", rctx.attr.build_file_content)

ruff_workaround_20269 = repository_rule(
    _ruff_workaround_20269_impl,
    doc = "Workaround for https://github.com/bazelbuild/bazel/issues/20269",
    attrs = {
        "build_file_content": attr.string(),
        "sha256": attr.string(),
        "url": attr.string(),
    },
)

def fetch_ruff(tag = RUFF_VERSIONS.keys()[0]):
    """A repository macro used from WORKSPACE to fetch ruff binaries

    Args:
        tag: a tag of ruff that we have mirrored, e.g. `v0.1.0`
    """
    version = tag.lstrip("v")

    # ruff changed their release artifact naming starting with v0.1.8
    if versions.is_at_least("0.1.8", version):
        url = "https://github.com/astral-sh/ruff/releases/download/{tag}/ruff-{version}-{plat}.{ext}"
    else:
        url = "https://github.com/astral-sh/ruff/releases/download/{tag}/ruff-{plat}.{ext}"

    for plat, sha256 in RUFF_VERSIONS[tag].items():
        fetch_rule = http_archive
        if plat.endswith("darwin"):
            fetch_rule = ruff_workaround_20269
        is_windows = plat.endswith("windows-msvc")

        maybe(
            fetch_rule,
            name = "ruff_" + plat,
            url = url.format(
                tag = tag,
                plat = plat,
                version = version,
                ext = "zip" if is_windows else "tar.gz",
            ),
            sha256 = sha256,
            build_file_content = """exports_files(["ruff", "ruff.exe"])""",
        )
