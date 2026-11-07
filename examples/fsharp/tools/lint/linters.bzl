"Define F# linter aspects"

load("@aspect_rules_lint//lint:fsharplint.bzl", "lint_fsharplint_aspect")
load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")

fsharplint = lint_fsharplint_aspect(
    binary = Label("@paket.main//dotnet-fsharplint/tools:dotnet-fsharplint"),
    config = Label("//:fsharplint.json"),
)

fsharplint_test = lint_test(aspect = fsharplint)
