load("@rules_proto//proto:defs.bzl", "proto_library")

package(default_visibility = ["//visibility:public"])

proto_library(
    name = "gadget_proto",
    srcs = ["gadget.proto"],
    import_prefix = "gadget/v1",
    strip_import_prefix = "/modules/prefixed",
)
