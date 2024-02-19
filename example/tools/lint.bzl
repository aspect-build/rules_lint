"Define linter aspects"

load("@aspect_rules_lint//lint:buf.bzl", "buf_lint_aspect")
load("@aspect_rules_lint//lint:eslint.bzl", "eslint_aspect")
load("@aspect_rules_lint//lint:flake8.bzl", "flake8_aspect")
load("@aspect_rules_lint//lint:golangci-lint.bzl", "golangci_lint_aspect")
load("@aspect_rules_lint//lint:lint_test.bzl", "make_lint_test")
load("@aspect_rules_lint//lint:pmd.bzl", "pmd_aspect")
load("@aspect_rules_lint//lint:ruff.bzl", "ruff_aspect")
load("@aspect_rules_lint//lint:shellcheck.bzl", "shellcheck_aspect")
load("@aspect_rules_lint//lint:vale.bzl", "vale_aspect")

buf = buf_lint_aspect(
    config = "@@//:buf.yaml",
)

eslint = eslint_aspect(
    binary = "@@//tools:eslint",
    # We trust that eslint will locate the correct configuration file for a given source file.
    # See https://eslint.org/docs/latest/use/configure/configuration-files#cascading-and-hierarchy
    configs = [
        "@@//:eslintrc",
        "@@//src/subdir:eslintrc",
    ],
)

eslint_test = make_lint_test(aspect = eslint)

flake8 = flake8_aspect(
    binary = "@@//tools:flake8",
    config = "@@//:.flake8",
)

flake8_test = make_lint_test(aspect = flake8)

pmd = pmd_aspect(
    binary = "@@//tools:pmd",
    rulesets = ["@@//:pmd.xml"],
)

pmd_test = make_lint_test(aspect = pmd)

ruff = ruff_aspect(
    binary = "@@//tools:ruff",
    configs = [
        "@@//:.ruff.toml",
        "@@//src/subdir:ruff.toml",
    ],
)

ruff_test = make_lint_test(aspect = ruff)

shellcheck = shellcheck_aspect(
    binary = "@@//tools:shellcheck",
    config = "@@//:.shellcheckrc",
)

shellcheck_test = make_lint_test(aspect = shellcheck)

golangci_lint = golangci_lint_aspect(
    binary = "@@//tools:golangci_lint",
    config = "@@//:.golangci.yaml",
)

golangci_lint_test = make_lint_test(aspect = golangci_lint)

vale = vale_aspect(
    binary = "@@//tools:vale",
    config = "@@//:.vale.ini",
    styles = "@@//tools:vale_styles",
)
