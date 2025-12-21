"""BUILD definition for the formatter binary"""

load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

package(default_visibility = ["//:__subpackages__"])

format_multirun(
    name = "format",
    # You can use standard gofmt instead of stricter gofumpt:
    # go = "@go_sdk//:bin/gofmt",
    go = "@aspect_rules_lint//format:gofumpt",
    visibility = ["//:__subpackages__"],
)
