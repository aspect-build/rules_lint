"Define Terraform linter aspects"

load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")
load("@aspect_rules_lint//lint:tflint.bzl", "lint_tflint_aspect")

tflint = lint_tflint_aspect(
    binary = "@aspect_rules_lint//lint:tflint_bin",
    config = Label("//:.tflint.hcl"),
    plugins = [
        Label("@tflint_plugin_google//:plugin"),
    ],
)

tflint_test = lint_test(aspect = tflint)
