# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "report_test")
load("//test:machine_output.bzl", "machine_groovy_report")
load("//tools/lint:linters.bzl", "groovy_test")

groovy_test(
    name = "groovy_has_violations",
    srcs = ["//src:groovy_files"],
    # This test is expected to fail because has_errors.groovy has lint violations
    tags = ["manual"],
)

machine_groovy_report(
    name = "machine_groovy_report",
    src = "//src:groovy_files",
)

report_test(
    name = "groovy_machine_output_test",
    expected_tool = "npm-groovy-lint",
    expected_uri = "src/has_errors.groovy",
    report = "machine_groovy_report",
)
