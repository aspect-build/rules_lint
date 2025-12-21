"Shell-specific machine report rules for testing."

# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "machine_report_rule")
load("//tools/lint:linters.bzl", "shellcheck")

machine_shellcheck_report = machine_report_rule(shellcheck)
