"Define linter aspects"

load("@aspect_rules_lint//lint:assert_no_lint_warnings.bzl", "assert_no_lint_warnings")
load("@aspect_rules_lint//lint:buf.bzl", "buf_lint_aspect")
load("@aspect_rules_lint//lint:eslint.bzl", "eslint_aspect")
load("@aspect_rules_lint//lint:flake8.bzl", "flake8_aspect")
load("@aspect_rules_lint//lint:pmd.bzl", "pmd_aspect")

buf = buf_lint_aspect(
    config = "@@//:buf.yaml",
)

eslint = eslint_aspect(
    binary = "@@//:eslint",
    config = "@@//:eslintrc",
)

flake8 = flake8_aspect(
    binary = "@@//:flake8",
    config = "@@//:.flake8",
)

flake8_test = assert_no_lint_warnings(aspect = flake8)

pmd = pmd_aspect(
    binary = "@@//:pmd",
    rulesets = ["@@//:pmd.xml"],
)

pmd_test = assert_no_lint_warnings(aspect = pmd)
