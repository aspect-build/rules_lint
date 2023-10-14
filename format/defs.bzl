"""Produce a multi-formatter that aggregates the supplier formatters.

TODO: user docs
"""

load("//format/private:formatter_binary.bzl", _fmt = "multi_formatter_binary")

def multi_formatter_binary(name, formatters):
    _fmt(
        name = name,
        # reverse the dictionary - bazel only supports labels as keys
        formatters = {v: k for k, v in formatters.items()},
    )
