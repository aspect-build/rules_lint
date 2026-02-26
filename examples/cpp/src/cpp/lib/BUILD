load("@rules_cc//cc:defs.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

exports_files(["get/.clang-tidy"])

cc_library(
    name = "hello-time",
    srcs = [
        "get/get-time.cc",
        "get/get-time.h",
        "hello-time.cc",
    ],
    hdrs = [
        "hello-time.h",
        "xhello-time.h",
    ],
    # Use copts so quotes are preserved; local_defines strips them and breaks string literals
    copts = ["-DLOCAL_DEFINE_IS_DEFINED=\\\"a_string\\\""],
    includes = ["."],
    visibility = ["//src/cpp/main:__pkg__"],
)
