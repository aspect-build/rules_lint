"Define linter aspects"

load("@aspect_rules_lint//lint:eslint.bzl", "eslint_aspect")

eslint = eslint_aspect(
    binary = "@@//:eslint",
    config = "@@//:eslintrc",
)
