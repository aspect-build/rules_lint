load("@aspect_rules_lint//format:defs.bzl", "format_multirun")
load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

package(default_visibility = ["//:__subpackages__"])

py_console_script_binary(
    name = "pyside6-qmlformat",
    pkg = "@pip//pyside6_essentials:pkg",
    script = "pyside6-qmlformat",
)

format_multirun(
    name = "format",
    qml = ":pyside6-qmlformat",
    visibility = ["//:__subpackages__"],
)
