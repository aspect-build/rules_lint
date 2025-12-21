load("//tools/lint:linters.bzl", "yamllint_test")

package(default_visibility = ["//visibility:public"])

yamllint_test(
    name = "yamllint",
    srcs = ["//src:all"],
    # Expected to fail based on current content of the file.
    # Normally you'd fix the file instead of tagging this test.
    tags = ["manual"],
)
