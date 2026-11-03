"Protobuf-specific machine report rules for testing."

# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "machine_report_rule")
load("//tools/lint:linters.bzl", "buf", "buf_modules")

machine_buf_report = machine_report_rule(buf)

machine_buf_modules_report = machine_report_rule(buf_modules)
