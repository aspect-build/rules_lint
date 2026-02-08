"Demonstrates how to enforce zero-lint-tolerance policy with tests"

load("//tools/lint:linters.bzl", "ktlint_test")

ktlint_test(
    name = "ktlint",
    srcs = ["//src:hello_kt"],
    expected_exit_code = 1,
)
