"Define linter aspects"

load("@aspect_rules_eslint//eslint:defs.bzl", "eslint_aspect")

eslint = eslint_aspect(
    binary = "//examples:eslint",
    config = "//examples/simple:.eslintrc.cjs",
)
