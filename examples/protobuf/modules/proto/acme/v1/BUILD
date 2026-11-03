load("@rules_proto//proto:defs.bzl", "proto_library")

package(default_visibility = ["//visibility:public"])

proto_library(
    name = "acme_proto",
    srcs = ["greeting.proto"],
    strip_import_prefix = "/modules/proto",
)
