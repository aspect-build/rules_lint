"""API for declaring a shellcheck lint aspect that visits sh_library rules.

Typical usage:

1. Use [fetch_shellcheck](#fetch_shellcheck) in WORKSPACE to call the `http_archive` calls to download binaries.
2. Use [shellcheck_binary](#shellcheck_binary) in `tools/BUILD.bazel` to declare the shellcheck target
3. Use [shellcheck_aspect](#shellcheck_aspect) in `tools/lint.bzl` to declare the shellcheck linter aspect:

```
load("@aspect_rules_lint//lint:shellcheck.bzl", "shellcheck_aspect")

shellcheck = shellcheck_aspect(
    binary = "@@//tools:shellcheck",
    config = "@@//:.shellcheckrc",
)
```
"""

load("@bazel_skylib//rules:native_binary.bzl", "native_binary")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//lint/private:lint_aspect.bzl", "report_file")

_MNEMONIC = "shellcheck"

def shellcheck_binary(name):
    """Wrapper around native_binary to select the correct shellcheck executable for the execution platform."""
    native_binary(
        name = name,
        src = select(
            {
                "@platforms//os:osx": "@shellcheck_darwin.x86_64//:shellcheck",
                "@aspect_rules_lint//lint:linux_x86": "@shellcheck_linux.x86_64//:shellcheck",
                "@aspect_rules_lint//lint:linux_aarch64": "@shellcheck_linux.aarch64//:shellcheck",
            },
            no_match_error = "Shellcheck hasn't been fetched for your platform",
        ),
        out = "shellcheck",
        visibility = ["//visibility:public"],
    )

def shellcheck_action(ctx, executable, srcs, config, report, use_exit_code = False):
    """Run shellcheck as an action under Bazel.

    Based on https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the shellcheck program
        srcs: bash files to be linted
        config: label of the .shellcheckrc file
        report: output file to generate
        use_exit_code: whether to fail the build when a lint violation is reported
    """
    inputs = srcs + [config]

    # Wire command-line options, see
    # https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md#options
    args = ctx.actions.args()
    args.add_all(srcs)

    if use_exit_code:
        command = "{shellcheck} $@ && touch {report}"
    else:
        command = "{shellcheck} $@ >{report} || true"

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [report],
        command = command.format(
            shellcheck = executable.path,
            report = report.path,
        ),
        arguments = [args],
        mnemonic = _MNEMONIC,
        tools = [executable],
    )

# buildifier: disable=function-docstring
def _shellcheck_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["sh_binary", "sh_library", "sh_test"]:
        return []

    report, info = report_file(_MNEMONIC, target, ctx)
    shellcheck_action(ctx, ctx.executable._shellcheck, [s for s in ctx.rule.files.srcs if s.is_source], ctx.file._config_file, report, ctx.attr.fail_on_violation)
    return [info]

def shellcheck_aspect(binary, config):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a shellcheck executable.
        config: the .shellcheckrc file
    """
    return aspect(
        implementation = _shellcheck_aspect_impl,
        attrs = {
            "fail_on_violation": attr.bool(),
            "_shellcheck": attr.label(
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

# Data manually mirrored from https://github.com/koalaman/shellcheck/releases
# TODO: add a mirror_shellcheck.sh script to automate this
SHELLCHECK_VERSIONS = {
    "v0.9.0": {
        "darwin.x86_64": "7d3730694707605d6e60cec4efcb79a0632d61babc035aa16cda1b897536acf5",
        "linux.x86_64": "700324c6dd0ebea0117591c6cc9d7350d9c7c5c287acbad7630fa17b1d4d9e2f",
        "linux.aarch64": "179c579ef3481317d130adebede74a34dbbc2df961a70916dd4039ebf0735fae",
    },
}

def fetch_shellcheck(version = SHELLCHECK_VERSIONS.keys()[0]):
    """A repository macro used from WORKSPACE to fetch binaries

    Args:
        version: a version of shellcheck that we have mirrored, e.g. `v0.9.0`
    """
    for plat, sha256 in SHELLCHECK_VERSIONS[version].items():
        maybe(
            http_archive,
            name = "shellcheck_{}".format(plat),
            url = "https://github.com/koalaman/shellcheck/releases/download/{version}/shellcheck-{version}.{plat}.tar.xz".format(
                version = version,
                plat = plat,
            ),
            strip_prefix = "shellcheck-{}".format(version),
            sha256 = sha256,
            build_file_content = """exports_files(["shellcheck"])""",
        )
