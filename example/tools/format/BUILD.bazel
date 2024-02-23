"""BUILD definition for the formatter binary

This is in its own package because it has so many loading-time symbols,
we don't want to trigger eager fetches of these for builds that don't want to run format.
"""

load("@aspect_rules_lint//format:defs.bzl", "multi_formatter_binary")
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")
load("@npm//:prettier/package_json.bzl", prettier = "bin")
load("@rules_java//java:defs.bzl", "java_binary")

package(default_visibility = ["//:__subpackages__"])

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
    name = "shfmt",
    actual = select({
        "@bazel_tools//src/conditions:linux_x86_64": "@shfmt_linux_x86_64//file:shfmt",
        "@bazel_tools//src/conditions:linux_aarch64": "@shfmt_linux_aarch64//file:shfmt",
        "@bazel_tools//src/conditions:darwin_arm64": "@shfmt_darwin_aarch64//file:shfmt",
        "@bazel_tools//src/conditions:darwin_x86_64": "@shfmt_darwin_x86_64//file:shfmt",
    }),
)

alias(
    name = "gofumpt",
    actual = select({
        "@io_bazel_rules_go//go/platform:darwin_amd64": "@com_github_mvdan_gofumpt_darwin_amd64//file",
        "@io_bazel_rules_go//go/platform:darwin_arm64": "@com_github_mvdan_gofumpt_darwin_arm64//file",
        "@io_bazel_rules_go//go/platform:linux_amd64": "@com_github_mvdan_gofumpt_linux_amd64//file",
        "@io_bazel_rules_go//go/platform:linux_arm64": "@com_github_mvdan_gofumpt_linux_arm64//file",
    }),
)

alias(
    name = "swiftformat",
    actual = select({
        "@bazel_tools//src/conditions:linux": "@swiftformat",
        "@bazel_tools//src/conditions:darwin": "@swiftformat_mac",
    }),
)

java_binary(
    name = "scalafmt",
    data = ["//:.scalafmt.conf"],
    main_class = "org.scalafmt.cli.Cli",
    runtime_deps = ["@maven//:org_scalameta_scalafmt_cli_2_13"],
)

native_binary(
    name = "yamlfmt",
    src = select(
        {
            "@bazel_tools//src/conditions:linux_x86_64": "@yamlfmt_Linux_x86_64//:yamlfmt",
            "@bazel_tools//src/conditions:linux_aarch64": "@yamlfmt_Linux_arm64//:yamlfmt",
            "@bazel_tools//src/conditions:darwin_x86_64": "@yamlfmt_Darwin_x86_64//:yamlfmt",
            "@bazel_tools//src/conditions:darwin_arm64": "@yamlfmt_Darwin_arm64//:yamlfmt",
        },
    ),
    out = "yamlfmt",
)

multi_formatter_binary(
    name = "format",
    cc = "@llvm_toolchain_llvm//:bin/clang-format",
    # Or ":gofumpt" if you want to use gofumpt instead of gofmt
    go = "@go_sdk//:bin/gofmt",
    java = ":java-format",
    javascript = ":prettier",
    jsonnet = ":jsonnetfmt",
    kotlin = ":ktfmt",
    markdown = ":prettier",
    protobuf = "//tools/lint:buf",
    python = "//tools/lint:ruff",
    scala = ":scalafmt",
    sh = ":shfmt",
    sql = ":prettier",
    starlark = "@buildifier_prebuilt//:buildifier",
    swift = ":swiftformat",
    terraform = ":terraform",
    yaml = ":yamlfmt",
)
