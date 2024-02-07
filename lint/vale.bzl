"""API for declaring a Vale lint aspect that visits markdown files.

Typical usage: TODO
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//lint/private:lint_aspect.bzl", "report_file")
load(":vale_versions.bzl", "VALE_VERSIONS")

_MNEMONIC = "Vale"

# buildifier: disable=function-docstring
def vale_action(ctx, executable, srcs, styles, config, report, use_exit_code = False):
    # First action, create an ini file with the StylesPath
    inputs = srcs + config + [styles]

    # Wire command-line options, see output of vale --help
    args = ctx.actions.args()
    args.add_all(srcs)
    args.add_all(["--config", config[0]])
    # args.add_all(["--stylesPath", styles.path])

    if use_exit_code:
        fail()
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
        vale_action(ctx, ctx.executable._vale, ctx.rule.files.srcs, ctx.file._styles, ctx.files._config, report, ctx.attr.fail_on_violation)
        return [info]

    return []

def vale_aspect(binary, configs, styles):
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
            "_config": attr.label_list(
                allow_files = True,
                mandatory = True,
                allow_empty = False,
                doc = "Config files",
                default = configs,
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

        # Library of Vale "styles" may be found at:
        # https://raw.githubusercontent.com/errata-ai/styles/master/library.json

        maybe(
            http_archive,
            name = "vale_Google",
            sha256 = "5f1510603337bb32f3c927872a73e7bfd494d7ad4d4f10fba8961a94ba481dbe",
            # Note: this is actually a directory, not a file
            build_file_content = """exports_files(["Google"])""",
            url = "https://github.com/errata-ai/Google/releases/download/v0.4.2/Google.zip",
        )
        maybe(
            http_archive,
            name = "vale_write-good",
            sha256 = "e0e86123266f7b82378e84a6183bb55d98c9b61528bcb734d17472ebc22cd415",
            # Note: this is actually a directory, not a file
            build_file_content = """exports_files(["write-good"])""",
            url = "https://github.com/errata-ai/write-good/releases/download/v0.4.0/write-good.zip",
        )
        # TODO: fetch other styles from the library
