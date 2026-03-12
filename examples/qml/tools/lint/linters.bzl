"Define QML linter aspects"

load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")
load("@aspect_rules_lint//lint:qmllint.bzl", "lint_qmllint_aspect")

qmllint = lint_qmllint_aspect(
    binary = Label("//tools/lint:pyside6-qmllint"),
    config = Label("//:.qmllint.ini"),
)

qmllint_test = lint_test(aspect = qmllint)
