"""API for declaring a Vale lint aspect that visits markdown files.

Typical usage: TODO
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//lint/private:lint_aspect.bzl", "report_file")
load(":vale_library.bzl", "fetch_styles")
load(":vale_versions.bzl", "VALE_VERSIONS")

_MNEMONIC = "Vale"

# buildifier: disable=function-docstring
def vale_action(ctx, executable, srcs, styles, config, report, use_exit_code = False):
    # First action, create an ini file with the StylesPath
    inputs = srcs + [config, styles]

    # Wire command-line options, see output of vale --help
    args = ctx.actions.args()
    args.add_all(srcs)
    args.add_all(["--config", config])
    args.add_all(["--output", "line"])

    if use_exit_code:
        ctx.actions.run_shell(
            inputs = inputs,
            outputs = [report],
            command = executable.path + " $@ && touch " + report.path,
            arguments = [args],
            mnemonic = _MNEMONIC,
            tools = [executable],
        )
    else:
        ctx.actions.run_shell(
            inputs = inputs,
            outputs = [report],
            tools = [executable],
            arguments = [args],
            command = executable.path + " $@ >" + report.path,
            mnemonic = _MNEMONIC,
        )

    return []

# buildifier: disable=function-docstring
def _vale_aspect_impl(target, ctx):
    if ctx.rule.kind in ["filegroup"]:  # TODO: look for tag too
        report, info = report_file(_MNEMONIC, target, ctx)
        vale_action(ctx, ctx.executable._vale, ctx.rule.files.srcs, ctx.file._styles, ctx.file._config, report, ctx.attr.fail_on_violation)
        return [info]

    return []

def vale_aspect(binary, config, styles):
    """A factory function to create a linter aspect.
    """
    return aspect(
        implementation = _vale_aspect_impl,
        attrs = {
            "fail_on_violation": attr.bool(),
            "_vale": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config": attr.label(
                allow_single_file = True,
                mandatory = True,
                doc = "Config file",
                default = config,
            ),
            "_styles": attr.label(
                default = styles,
                allow_single_file = True,
            ),
        },
    )

def fetch_vale(tag = VALE_VERSIONS.keys()[0]):
    """A repository macro used from WORKSPACE to fetch vale binaries

    Args:
        tag: a tag of vale that we have mirrored, e.g. `v3.0.5`
    """
    version = tag.lstrip("v")
    url = "https://github.com/errata-ai/vale/releases/download/{tag}/vale_{version}_{plat}.{ext}"

    for plat, sha256 in VALE_VERSIONS[tag].items():
        is_windows = plat.startswith("Windows")

        maybe(
            http_archive,
            name = "vale_" + plat,
            url = url.format(
                tag = tag,
                plat = plat,
                version = version,
                ext = "zip" if is_windows else "tar.gz",
            ),
            sha256 = sha256,
            build_file_content = """exports_files(["vale", "vale.exe"])""",
        )

        fetch_styles()
