"""BUILD definition for the formatter binary

This is in its own package because it has so many loading-time symbols,
we don't want to trigger eager fetches of these for builds that don't want to run format.
"""

load("@aspect_rules_lint//format:defs.bzl", "multi_formatter_binary")
load("@npm//:prettier/package_json.bzl", prettier = "bin")
load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

package(default_visibility = ["//:__pkg__"])

alias(
    name = "jsonnetfmt",
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

alias(
    name = "ruff",
    actual = select({
        "@bazel_tools//src/conditions:linux_x86_64": "@ruff_x86_64-unknown-linux-gnu//:ruff",
        "@bazel_tools//src/conditions:linux_aarch64": "@ruff_aarch64-unknown-linux-gnu//:ruff",
        "@bazel_tools//src/conditions:darwin_arm64": "@ruff_aarch64-apple-darwin//:ruff",
        "@bazel_tools//src/conditions:darwin_x86_64": "@ruff_x86_64-apple-darwin//:ruff",
    }),
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
    go = "@go_sdk//:bin/gofmt",
    java = ":java-format",
    javascript = ":prettier",
    jsonnet = ":jsonnetfmt",
    kotlin = ":ktfmt",
    python = ":ruff",
    starlark = "@buildifier_prebuilt//:buildifier",
    swift = ":swiftformat",
    terraform = ":terraform",
)
