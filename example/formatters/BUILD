load("@npm//:prettier/package_json.bzl", prettier = "bin")
load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

package(default_visibility = ["//:__pkg__"])

alias(
    name = "jsonnet",
    actual = select({
        "@bazel_tools//src/conditions:linux_x86_64": "@jsonnet_linux_x86_64//:jsonnetfmt",
        "@bazel_tools//src/conditions:linux_aarch64": "@jsonnet_linux_aarch64//:jsonnetfmt",
        "@bazel_tools//src/conditions:darwin_arm64": "@jsonnet_macos_aarch64//:jsonnetfmt",
        "@bazel_tools//src/conditions:darwin_x86_64": "@jsonnet_macos_x86_64//:jsonnetfmt",
    }),
)

alias(
    name = "terraform",
    actual = select({
        "@bazel_tools//src/conditions:linux": "@terraform_linux_x86_64//:terraform",
        "@bazel_tools//src/conditions:darwin_arm64": "@terraform_macos_aarch64//:terraform",
        "@bazel_tools//src/conditions:darwin_x86_64": "@terraform_macos_x86_64//:terraform",
    }),
)

# bazel run :black -- --help
py_console_script_binary(
    name = "black",
    pkg = "@pip//black:pkg",
)

prettier.prettier_binary(
    name = "prettier",
    # Allow the binary to be run outside bazel
    env = {"BAZEL_BINDIR": "."},
)
