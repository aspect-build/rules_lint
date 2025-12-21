"Demonstrates how to enforce zero-lint-tolerance policy with tests"

load("//tools/lint:linters.bzl", "ktlint_test")

ktlint_test(
    name = "ktlint",
    srcs = ["//src:hello_kt"],
    # Expected to fail based on current content of the file.
    # Normally you'd fix the file instead of tagging this test.
    tags = ["manual"],
)
