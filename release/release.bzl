"""This module provides the macros for performing a release.
"""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("@bazel_tools//tools/build_defs/hash:hash.bzl", "tools", _sha256 = "sha256")
load("@rules_go//go:def.bzl", "go_binary")

def _sha256_impl(ctx):
    out = _sha256(ctx, ctx.file.artifact)
    files = depset(direct = [out])
    runfiles = ctx.runfiles(files = [out])
    return [DefaultInfo(files = files, runfiles = runfiles)]

sha256 = rule(
    implementation = _sha256_impl,
    attrs = dicts.add({
        "artifact": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The artifact whose sha256 value should be calculated.",
        ),
    }, tools),
    doc = "Calculate the SHA256 hash value for a file.",
    provides = [DefaultInfo],
)

# buildifier: disable=function-docstring
def local_plugin(name, binary, path, **kwargs):
    out = "_{}.out".format(name)
    sum = "_{}.sum".format(name)

    # Copy the default output of the binary rule.
    # The path might be hard to predict, e.g. go_binary has an extra segment
    copy_file(
        name = out,
        src = binary,
        out = path,
    )

    # The plugin API requires a checksum for SecureConfig:
    # https://github.com/hashicorp/go-plugin/pull/25
    sha256(
        name = sum,
        artifact = out,
    )

    # Target you can build to do local dev
    native.filegroup(
        name = name,
        srcs = [out, sum],
        **kwargs
    )

PLATFORMS = [
    struct(os = "darwin", arch = "amd64", ext = "", gc_linkopts = ["-s", "-w"]),
    struct(os = "darwin", arch = "arm64", ext = "", gc_linkopts = ["-s", "-w"]),
    struct(os = "linux", arch = "amd64", ext = "", gc_linkopts = ["-s", "-w"]),
    struct(os = "linux", arch = "arm64", ext = "", gc_linkopts = ["-s", "-w"]),
    struct(os = "windows", arch = "amd64", ext = ".exe", gc_linkopts = []),
]

def multi_platform_binaries(name, embed, prefix = ""):
    """The multi_platform_binaries macro creates a go_binary for each platform.

    Args:
        name: the name of the filegroup containing all go_binary targets produced
            by this macro.
        embed: the list of targets passed to each go_binary target in this
            macro.
        prefix: an optional prefix added to the output Go binary file name.
    """
    targets = []
    for platform in PLATFORMS:
        target_name = "{}-{}-{}".format(name, platform.os, platform.arch)
        go_binary(
            name = target_name,
            out = "{}{}-{}_{}{}".format(prefix, name, platform.os, platform.arch, platform.ext),
            embed = embed,
            gc_linkopts = platform.gc_linkopts,
            goarch = platform.arch,
            goos = platform.os,
            pure = "on",
            visibility = ["//visibility:public"],
        )
        targets.append(Label("//{}:{}".format(native.package_name(), target_name)))

    native.filegroup(
        name = name,
        srcs = targets,
    )

def release(name, targets):
    """The release macro creates the artifact copier script.

    It's an executable script that copies all artifacts produced by the given
    targets into the provided destination. See .github/workflows/release.yml.

    Args:
        name: the name of the genrule.
        targets: a list of filegroups passed to the artifact copier.
    """
    native.genrule(
        name = name,
        srcs = targets,
        outs = ["release.sh"],
        executable = True,
        cmd = "./$(location //release:create_release.sh) {locations} > \"$@\"".format(
            locations = " ".join(["$(locations {})".format(target) for target in targets]),
        ),
        tools = ["//release:create_release.sh"],
    )
