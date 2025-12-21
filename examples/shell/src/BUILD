load("@aspect_rules_lint//format:defs.bzl", "format_test")
load("@rules_shell//shell:sh_library.bzl", "sh_library")

package(default_visibility = ["//visibility:public"])

sh_library(
    name = "hello",
    srcs = ["hello.sh"],
)

# Cause a test failure when files are not formatted.
# This is useful when you have no other way to check formatting on CI; see documentation.
format_test(
    name = "format_files_test",
    srcs = ["hello.sh"],
)
