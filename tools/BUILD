load("@bazel_lib//:bzl_library.bzl", "bzl_library")
load("@bazelrc-preset.bzl", "bazelrc_preset")

bazelrc_preset(
    name = "preset",
    strict = True,
    tags = ["manual"],
)

bzl_library(
    name = "integrity",
    srcs = ["integrity.bzl"],
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "version",
    srcs = ["version.bzl"],
    visibility = ["//visibility:public"],
)
