load("@rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")

package(default_visibility = ["//visibility:public"])

kt_jvm_library(
    name = "hello_kt",
    srcs = ["hello.kt"],
)

filegroup(
    name = "all",
    srcs = [":hello_kt"],
)
