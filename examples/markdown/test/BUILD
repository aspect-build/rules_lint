# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "report_results_count_test", "report_test")
load("//test:machine_output.bzl", "machine_rumdl_report")
load("//tools/lint:linters.bzl", "rumdl_test")

package(default_visibility = ["//visibility:public"])

rumdl_test(
    name = "rumdl_bad",
    srcs = ["//src:bad"],
    expected_exit_code = 1,
)

rumdl_test(
    name = "rumdl_good",
    srcs = ["//src:good"],
)

rumdl_test(
    name = "rumdl_lowercase_r_markdown_bad",
    srcs = ["//src:lowercase_r_markdown_bad"],
    expected_exit_code = 1,
)

rumdl_test(
    name = "rumdl_combined",
    srcs = ["//src:combined"],
    expected_exit_code = 1,
)

machine_rumdl_report(
    name = "machine_rumdl_report",
    src = "//src:bad",
)

report_test(
    name = "rumdl_machine_output_test",
    expected_tool = "rumdl",
    expected_uri = "src/bad.md",
    report = "machine_rumdl_report",
)

report_results_count_test(
    name = "rumdl_machine_results_count_test",
    expected_count = 3,
    report = "machine_rumdl_report",
)
