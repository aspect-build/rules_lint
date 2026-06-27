load("//tools/lint:linters.bzl", "golangci_lint_test")

# golangci-lint flags the non-constant format string in hello.go (govet printf),
# so the linter exits 1.
golangci_lint_test(
    name = "golangci_lint_finds_issue",
    srcs = ["//src:hello"],
    expected_exit_code = 1,
)

# The greeting library is clean, so the linter exits 0 (no false positives).
golangci_lint_test(
    name = "golangci_lint_clean",
    srcs = ["//src:greeting"],
    expected_exit_code = 0,
)
