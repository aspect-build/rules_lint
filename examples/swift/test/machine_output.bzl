"Swift-specific machine report rules for testing."

# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "machine_report_rule")
load("//tools/lint:linters.bzl", "swiftlint", "swiftlint_nested_config", "swiftlint_verbose")

machine_swiftlint_report = machine_report_rule(swiftlint)
machine_swiftlint_nested_config_report = machine_report_rule(swiftlint_nested_config)
machine_swiftlint_verbose_report = machine_report_rule(swiftlint_verbose)
