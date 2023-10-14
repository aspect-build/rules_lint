"""Produce a multi-formatter that aggregates the supplier formatters.

TODO: user docs
"""

load("//format/private:formatter_binary.bzl", "formatter_binary_lib")

formatter_binary = rule(
    doc = "Produces an executable that aggregates the supplied formatter binaries",
    implementation = formatter_binary_lib.implementation,
    attrs = formatter_binary_lib.attrs,
    executable = True,
)
