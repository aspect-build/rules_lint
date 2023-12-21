load("@pip//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "py_binary")

py_binary(
    name = "main",
    srcs = ["main.py"],
    main = "main.py",
    deps = [
        "//src/py_types/testing_deps/bar:boo",
        "//src/py_types/testing_deps/foo:fizz",
        "//src/py_types/util",
        requirement("requests"),
        requirement("types-requests"),
    ],
)
