"""Workaround https://github.com/bazelbuild/bazel/issues/14009 to support Bazel prior to 8.3 & 9

TODO(3.0): when we drop support for Bazel 7 and 8.2, we can simplify this.
"""
load("@aspect_rules_js//js:defs.bzl", "js_binary")
load("@bazel_features//:features.bzl", "bazel_features")

def patcher_binary(name):
    """Create a js_binary that can be used to run the patcher.mjs script.

    Args:
        name: The name of the patcher binary.
    """
    diff_bin_copy = "_{}.diff_bin".format(name)
    env = {}
    data = []
    if bazel_features.toolchains.genrule_accepts_toolchain_types:
        native.genrule(
            name = diff_bin_copy,
            outs = ["diff_bin"],
            cmd = "cp $(DIFF_BIN) $(location :diff_bin)",
            executable = True,
            toolchains = ["@diff.bzl//diff/toolchain:execution_type"],
        )
        data.append(diff_bin_copy)
        env["DIFF_BIN"] = "$(rlocationpath {})".format(diff_bin_copy)

    js_binary(
        name = name,
        data = data,
        entry_point = "patcher.mjs",
        env = env,
        log_level = select({
            "@aspect_rules_lint//lint:debug.enabled": "debug",
            "//conditions:default": "error",
        }),
        # Because aspect visibility rules are not on by default.
        visibility = ["//visibility:public"],
    )
