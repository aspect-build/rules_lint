"""Definition of the linter binary.

This is in its own package because it has many loading-time symbols, so builds that do not run
lint do not eagerly fetch it.
"""

load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

package(default_visibility = ["//:__subpackages__"])

py_console_script_binary(
    name = "sqlfluff",
    pkg = "@pip//sqlfluff:pkg",
)
