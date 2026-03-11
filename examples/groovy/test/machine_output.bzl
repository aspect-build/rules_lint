"Extracts the machine-readable SARIF report from a target that has been linted with rules_lint."

# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "machine_report_rule")
load("//tools/lint:linters.bzl", "groovy")

machine_groovy_report = machine_report_rule(groovy)
