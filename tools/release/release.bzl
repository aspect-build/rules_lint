"""This module provides the macros for performing a release.
"""

load("@io_bazel_rules_go//go:def.bzl", "go_binary")

PLATFORMS = [
    struct(os = "darwin", arch = "amd64", ext = "", gc_linkopts = ["-s", "-w"]),
    struct(os = "darwin", arch = "arm64", ext = "", gc_linkopts = ["-s", "-w"]),
    struct(os = "freebsd", arch = "amd64", ext = "", gc_linkopts = ["-s", "-w"]),
    struct(os = "linux", arch = "amd64", ext = "", gc_linkopts = ["-s", "-w"]),
    struct(os = "linux", arch = "arm64", ext = "", gc_linkopts = ["-s", "-w"]),
    struct(os = "linux", arch = "s390x", ext = "", gc_linkopts = ["-s", "-w"]),
    struct(os = "windows", arch = "amd64", ext = ".exe", gc_linkopts = []),
]

def _hash(ctx, algo, file):
    coreutils = ctx.toolchains["@bazel_lib//lib:coreutils_toolchain_type"]
    out = ctx.actions.declare_file("{}.{}".format(file.basename, algo), sibling = file)
    ctx.actions.run_shell(
        outputs = [out],
        inputs = [file],
        tools = [coreutils.coreutils_info.bin],
        # coreutils has --no-names option but it doesn't work in current version, so we have to use cut.
        command = """HASH=$({coreutils} hashsum --{algo} {src} | {coreutils} cut -f1 -d " ") && {coreutils} echo -e "$HASH {basename}" > {out}""".format(
            coreutils = coreutils.coreutils_info.bin.path,
            algo = algo,
            src = file.path,
            basename = file.basename,
            out = out.path,
        ),
        toolchain = "@bazel_lib//lib:coreutils_toolchain_type",
    )
    return out

def _impl(ctx):
    # Create actions to generate the three output files.
    # Actions are run only when the corresponding file is requested.

    md5out = _hash(ctx, "md5", ctx.file.src)
    sha1out = _hash(ctx, "sha1", ctx.file.src)
    sha256out = _hash(ctx, "sha256", ctx.file.src)

    # By default (if you run `bazel build` on this target, or if you use it as a
    # source of another target), only the sha256 is computed.
    return [
        DefaultInfo(
            files = depset([sha256out]),
        ),
        OutputGroupInfo(
            md5 = depset([md5out]),
            sha1 = depset([sha1out]),
            sha256 = depset([sha256out]),
        ),
    ]

_hashes = rule(
    implementation = _impl,
    toolchains = [
        "@bazel_lib//lib:coreutils_toolchain_type",
    ],
    attrs = {
        "src": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
    },
)

def multi_platform_go_binaries(name, embed, prefix = "", **kwargs):
    """The multi_platform_go_binaries macro creates a go_binary for each platform.

    Args:
        name: the name of the filegroup containing all go_binary targets produced
            by this macro.
        embed: the list of targets passed to each go_binary target in this
            macro.
        prefix: an optional prefix added to the output Go binary file name.
        **kwargs: extra arguments.
    """
    targets = []
    for platform in PLATFORMS:
        target_name = "{}-{}-{}".format(name, platform.os, platform.arch)
        target_label = Label("//{}:{}".format(native.package_name(), target_name))
        go_binary(
            name = target_name,
            out = "{}{}-{}_{}{}".format(prefix, name, platform.os, platform.arch, platform.ext),
            embed = embed,
            gc_linkopts = platform.gc_linkopts,
            goarch = platform.arch,
            goos = platform.os,
            pure = "on",
            visibility = ["//visibility:public"],
            **kwargs
        )
        hashes_name = "{}_hashes".format(target_name)
        hashes_label = Label("//{}:{}".format(native.package_name(), hashes_name))
        _hashes(
            name = hashes_name,
            src = target_label,
            **kwargs
        )
        targets.extend([target_label, hashes_label])

    native.filegroup(
        name = name,
        srcs = targets,
        **kwargs
    )
