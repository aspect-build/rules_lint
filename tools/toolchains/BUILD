load("@bazel_lib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ["//visibility:public"])

toolchain_type(name = "sarif_parser_toolchain_type")

bzl_library(
    name = "register",
    srcs = ["register.bzl"],
    deps = [
        "//tools:version",
        "@aspect_bazel_lib//lib/private:source_toolchains_repo",
        "@aspect_rules_lint//tools/toolchains:sarif_parser_toolchain",
    ],
)

bzl_library(
    name = "sarif_parser_toolchain",
    srcs = ["sarif_parser_toolchain.bzl"],
    deps = [
        "//tools:integrity",
        "//tools:version",
    ],
)
