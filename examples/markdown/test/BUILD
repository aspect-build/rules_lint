# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "report_test")
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

machine_rumdl_report(
    name = "machine_rumdl_report",
    src = "//src:bad",
)

report_test(
    name = "rumdl_machine_output_test",
    expected_tool = "rumdl",
    expected_uri = "examples/markdown/src/bad.md",
    report = "machine_rumdl_report",
)
