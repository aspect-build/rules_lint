"Define Groovy linter aspects"

load("@aspect_rules_lint//lint:groovy.bzl", "lint_groovy_aspect")
load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")

groovy = lint_groovy_aspect(
    binary = Label("//tools/lint:groovy-lint"),
    config = Label(":.groovylintrc.json"),
)

groovy_test = lint_test(aspect = groovy)
