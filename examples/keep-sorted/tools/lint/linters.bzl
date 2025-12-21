"Setup keep-sorted linter"

load("@aspect_rules_lint//lint:defs.bzl", "lint_test")
load("@aspect_rules_lint//lint:keep_sorted.bzl", "lint_keep_sorted_aspect")

keep_sorted = lint_keep_sorted_aspect(
    binary = Label("@com_github_google_keep_sorted//:keep-sorted"),
)

keep_sorted_test = lint_test(aspect = keep_sorted)
