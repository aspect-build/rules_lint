load("@rules_python//python:defs.bzl", "py_library")

package(default_visibility = ["//visibility:public"])

exports_files(["ruff.toml"])

py_library(
    name = "unused_import",
    srcs = ["unused_import.py"],
)

py_library(
    name = "unsupported_operator",
    srcs = ["unsupported_operator.py"],
)

py_library(
    name = "call_non_callable",
    srcs = ["call_non_callable.py"],
)

py_library(
    name = "missing_doc_arg",
    srcs = ["missing_doc_arg.py"],
)

py_library(
    name = "uses_dependency",
    srcs = ["uses_dependency.py"],
    deps = ["//src/python_lib:py_dependency"],
)

py_library(
    name = "uses_eval",
    srcs = ["uses_eval.py"],
)

py_library(
    name = "uses_dependency_correctly",
    srcs = ["uses_dependency_correctly.py"],
    deps = ["//src/python_lib:py_dependency"],
)

filegroup(
    name = "unused_import_pyi",
    srcs = ["unused_import.pyi"],
    tags = ["python"],
)

filegroup(
    name = "all",
    srcs = [
        ":call_non_callable",
        ":missing_doc_arg",
        ":unsupported_operator",
        ":unused_import",
        ":uses_dependency",
        ":uses_eval",
    ],
)
