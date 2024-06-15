load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library")

cc_library(
    name = "hello-greet",
    srcs = ["hello-greet.cc"],
    hdrs = ["hello-greet.h"],
    includes = ["."],
)

cc_binary(
    name = "hello-world",
    srcs = ["hello-world.cc"],
    deps = [
        ":hello-greet",
        "//src/cpp/lib:hello-time",
    ],
    includes = ["."],
)

cc_library(
    name = "hello-greet-with-error",
    srcs = ["hello-greet-with-error.cc"],
    hdrs = ["hello-greet-with-error.h"],
    includes = ["."],
    tags = ["manual"],
)
