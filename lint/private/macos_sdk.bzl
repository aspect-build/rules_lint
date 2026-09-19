"""Derive the macOS SDK root from a cc toolchain's built-in include dirs."""

def macos_sdk_root(built_in_include_directories):
    """Return the macOS SDK root (a `<...>.sdk` path) from the toolchain's
    built-in include dirs, or "" if none is found.

    Fallback for when `cc_toolchain.sysroot` is unset. clang-tidy runs as its
    own binary (often the hermetic one from toolchains_llvm), but its compiler
    flags come from whichever C++ toolchain is registered as the default. When
    none is registered, that's Bazel's auto-detected host toolchain
    (`@local_config_cc`). It leaves `builtin_sysroot` unset because the host
    clang self-resolves a default SDK. The SDK path still shows up in
    `built_in_include_directories` though (Bazel scrapes those from `clang -v`),
    so we recover the `.sdk` root from there.

    Uses `rfind` so an unrelated earlier `.sdk` path component (e.g. a user
    directory `/Users/foo.sdk/...`) can't mis-truncate the real SDK root.

    Args:
        built_in_include_directories: `cc_toolchain.built_in_include_directories`.

    Returns:
        The `.sdk` root path, or "" if no SDK dir is present.
    """
    for d in built_in_include_directories:
        idx = d.rfind(".sdk/")
        if idx != -1:
            return d[:idx + len(".sdk")]
    return ""
