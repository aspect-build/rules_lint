"Define linter aspects"

load("@aspect_rules_lint//lint:eslint.bzl", "eslint_aspect")
load("@aspect_rules_lint//lint:buf.bzl", "buf_lint_aspect")

buf = buf_lint_aspect(
    config = "@@//:buf.yaml",
)

eslint = eslint_aspect(
    binary = "@@//:eslint",
    config = "@@//:eslintrc",
)
