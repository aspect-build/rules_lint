load("@rules_python//python:defs.bzl", "py_binary")

package(default_visibility = ["//:__subpackages__"])

# Used instead of py_console_script_binary to avoid an extra error log
py_binary(
    name = "qmllint",
    srcs = ["qmllint_wrapper.py"],
    main = "qmllint_wrapper.py",
    deps = [
        "@pip//pyside6_essentials",
    ],
)
