"Define Markdown linter aspects"

load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")
load("@aspect_rules_lint//lint:rumdl.bzl", "lint_rumdl_aspect")

rumdl = lint_rumdl_aspect(
    binary = Label("@aspect_rules_lint//lint:rumdl_bin"),
    config = Label("//:.rumdl.toml"),
    data = [Label("//src:link_targets")],
)

rumdl_test = lint_test(aspect = rumdl)
