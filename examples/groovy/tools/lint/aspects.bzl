load("@aspect_rules_lint//lint:groovy.bzl", "lint_groovy_aspect")

groovy = lint_groovy_aspect(
    binary = Label("//tools/lint:groovy-lint"),
    config = Label("//tools/lint:.groovylintrc.json"),
)
