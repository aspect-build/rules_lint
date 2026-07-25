"Define SQL linter aspects"

load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")
load("@aspect_rules_lint//lint:sqlfluff.bzl", "lint_sqlfluff_aspect")

sqlfluff = lint_sqlfluff_aspect(
    binary = Label("//tools/lint:sqlfluff"),
    config = Label("//:.sqlfluff"),
)

sqlfluff_test = lint_test(aspect = sqlfluff)
