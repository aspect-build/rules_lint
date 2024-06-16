load("@rules_cc//cc:defs.bzl", "cc_library")

exports_files(["get/.clang-tidy"])

cc_library(
    name = "hello-time",
    srcs = ["hello-time.cc", "get/get-time.cc", "get/get-time.h"],
    hdrs = ["hello-time.h", "xhello-time.h"],
    includes = ["."],
    visibility = ["//src/cpp/main:__pkg__"],
)
