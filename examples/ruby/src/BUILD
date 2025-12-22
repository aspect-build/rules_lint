load("@rules_ruby//ruby:defs.bzl", "rb_library")

package(default_visibility = ["//visibility:public"])

rb_library(
    name = "hello_ruby",
    srcs = ["hello.rb"],
)

filegroup(
    name = "all",
    srcs = [":hello_ruby"],
)
