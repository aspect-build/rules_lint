"Define linter aspects"

load("@aspect_rules_lint//lint:golangci_lint.bzl", "lint_golangci_lint_aspect")
load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")

golangci_lint = lint_golangci_lint_aspect(
    binary = Label("@aspect_rules_lint//lint:golangci_lint_bin"),
    config = Label("@//:.golangci.yml"),
)

golangci_lint_test = lint_test(aspect = golangci_lint)
