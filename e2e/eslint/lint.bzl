"Define linter aspects"

load("@aspect_rules_lint//lint:defs.bzl", "eslint_aspect")

eslint = eslint_aspect(
    binary = "@@//:eslint",
    config = "@@//simple:.eslintrc.yml",
)
