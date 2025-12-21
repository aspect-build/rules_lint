load("@rules_proto//proto:defs.bzl", "proto_library")

package(default_visibility = ["//visibility:public"])

proto_library(
    name = "unused",
    srcs = ["unused.proto"],
)

proto_library(
    name = "foo_proto",
    srcs = ["file.proto"],
    deps = [":unused"],
)
