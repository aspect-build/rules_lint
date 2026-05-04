"Demonstrates how to enforce zero-lint-tolerance policy with tests"

# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "report_test")
load("//test:machine_output.bzl", "machine_swiftlint_nested_config_report", "machine_swiftlint_report", "machine_swiftlint_verbose_report")
load(
    "//tools/lint:linters.bzl",
    "swiftlint_baseline_test",
    "swiftlint_default_config_test",
    "swiftlint_nested_config_test",
    "swiftlint_nested_deeper_nearest_config_test",
    "swiftlint_nested_without_declared_config_test",
    "swiftlint_test",
)

package(default_visibility = ["//visibility:public"])

swiftlint_test(
    name = "swiftlint",
    srcs = ["//src:lint"],
    expected_exit_code = 2,
)

swiftlint_baseline_test(
    name = "swiftlint_baseline",
    srcs = ["//src:baseline"],
)

swiftlint_default_config_test(
    name = "swiftlint_default_config",
    srcs = ["//src:default_config"],
)

swiftlint_nested_config_test(
    name = "swiftlint_nested_config",
    srcs = ["//src:nested_config"],
    expected_exit_code = 2,
)

swiftlint_nested_deeper_nearest_config_test(
    name = "swiftlint_nested_deeper_nearest_config",
    srcs = ["//src:nested_deeper_nearest_config"],
)

swiftlint_nested_without_declared_config_test(
    name = "swiftlint_nested_without_declared_config",
    srcs = ["//src:nested_without_declared_config"],
)

machine_swiftlint_report(
    name = "machine_swiftlint_report",
    src = "//src:lint",
)

machine_swiftlint_nested_config_report(
    name = "machine_swiftlint_nested_config_report",
    src = "//src:nested_config",
)

machine_swiftlint_verbose_report(
    name = "machine_swiftlint_verbose_report",
    src = "//src:verbose",
)

report_test(
    name = "swiftlint_machine_output_test",
    expected_tool = "SwiftLint",
    expected_uri = "src/lintme.swift",
    report = "machine_swiftlint_report",
)

report_test(
    name = "swiftlint_nested_config_machine_output_test",
    expected_tool = "SwiftLint",
    expected_uri = "src/nested/lintme.swift",
    report = "machine_swiftlint_nested_config_report",
)

report_test(
    name = "swiftlint_verbose_machine_output_test",
    expected_tool = "SwiftLint",
    expected_uri = "src/lintme.swift",
    report = "machine_swiftlint_verbose_report",
)
