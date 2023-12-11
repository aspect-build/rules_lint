"Define linter aspects"

load("@aspect_rules_lint//lint:buf.bzl", "buf_lint_aspect")
load("@aspect_rules_lint//lint:eslint.bzl", "eslint_aspect")
load("@aspect_rules_lint//lint:flake8.bzl", "flake8_aspect")
load("@aspect_rules_lint//lint:lint_test.bzl", "make_lint_test")
load("@aspect_rules_lint//lint:mypy.bzl", "mypy_aspect")
load("@aspect_rules_lint//lint:pmd.bzl", "pmd_aspect")
load("@aspect_rules_lint//lint:ruff.bzl", "ruff_aspect")
load("@aspect_rules_lint//lint:shellcheck.bzl", "shellcheck_aspect")

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

mypy = mypy_aspect(
    binary = "@@//tools:mypy",
    configs = ["@@//:mypy.ini"],
)

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

shellcheck = shellcheck_aspect(
    binary = "@@//tools:shellcheck",
    config = "@@//:.shellcheckrc",
)

shellcheck_test = make_lint_test(aspect = shellcheck)
