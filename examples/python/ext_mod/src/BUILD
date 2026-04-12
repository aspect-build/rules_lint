load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_python//python:defs.bzl", "py_library")

write_file(
    name = "py_code_generator",
    out = "generated.py",
    content = ["import os"],
)

py_library(name = "generated",
           srcs = [":generated.py"],
           imports = ["."],
           visibility = ["//visibility:public"],
)
