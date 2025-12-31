load("@aspect_rules_py//py:defs.bzl", "py_binary")
load("//tools/pytest:defs.bzl", "py_test")

py_binary(
    name = "app_bin",
    srcs = ["__main__.py"],
    main = "__main__.py",
    visibility = ["//:__subpackages__"],
    deps = [
        "@pip//requests",
        "@pip//ruamel_yaml",
    ],
)

py_test(
    name = "app_test",
    srcs = ["app_test.py"],
)
