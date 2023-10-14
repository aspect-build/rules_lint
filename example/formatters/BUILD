"""BUILD definition for the formatter binary

This is in its own package because it has so many loading-time symbols,
we don't want to trigger eager fetches of these for builds that don't want to run format.
"""

load("@aspect_rules_lint//format:defs.bzl", "multi_formatter_binary")
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

java_binary(
    name = "java-format",
    jvm_flags = [
        "--add-exports jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED",
        "--add-exports jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED",
        "--add-exports jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED",
        "--add-exports jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED",
        "--add-exports jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED",
    ],
    main_class = "com.google.googlejavaformat.java.Main",
    runtime_deps = ["@google-java-format//jar"],
)

java_binary(
    name = "ktfmt",
    main_class = "com.facebook.ktfmt.cli.Main",
    runtime_deps = ["@ktfmt//jar"],
)

alias(
    name = "swiftformat",
    # TODO: keith says it would be okay to upstream a proper toolchain for this
    # https://github.com/bazelbuild/rules_swift/issues/864
    actual = select({
        "@bazel_tools//src/conditions:linux": "@swiftformat",
        "@bazel_tools//src/conditions:darwin": "@swiftformat_mac",
    }),
)

multi_formatter_binary(
    name = "format",
    formatters = {
        # "Python": ":black",
        # "Starlark": "@buildifier_prebuilt//:buildifier",
        # "Jsonnet": ":jsonnet",
        #"Terraform": ":terraform",
        # "JavaScript": ":prettier",
        # "Kotlin": ":ktfmt",
        # "Java": ":java-format",
        # FIXME: doesn't work with bzlmod
        # "Go": "@go_sdk//:bin/gofmt",
        "Swift": ":swiftformat",
    },
)
