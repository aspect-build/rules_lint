"Python-specific machine report rules for testing."

# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "machine_report_rule")
load("//tools/lint:linters.bzl", "flake8", "pylint", "ruff", "ty")

machine_ruff_report = machine_report_rule(ruff)

machine_ty_report = machine_report_rule(ty)

machine_flake8_report = machine_report_rule(flake8)

machine_pylint_report = machine_report_rule(pylint)
