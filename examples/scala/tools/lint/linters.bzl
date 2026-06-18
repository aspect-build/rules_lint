"Set up scalafix linter"

load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")
load("@aspect_rules_lint_scala//:scalafix.bzl", "lint_scalafix_aspect")

scalafix = lint_scalafix_aspect(
    binary = Label("//tools/lint:scalafix"),
    config = Label("//:.scalafix.conf"),
    semantic = True,
)

scalafix_test = lint_test(aspect = scalafix)
