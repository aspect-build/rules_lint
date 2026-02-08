# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "report_test")
load("//test:machine_output.bzl", "machine_shellcheck_report")
load("//tools/lint:linters.bzl", "shellcheck_test")

package(default_visibility = ["//visibility:public"])

shellcheck_test(
    name = "shellcheck",
    srcs = ["//src:hello"],
    expected_exit_code = 1,
)

machine_shellcheck_report(
    name = "machine_shellcheck_report",
    src = "//src:hello",
)

report_test(
    name = "shellcheck_machine_output_test",
    expected_tool = "ShellCheck",
    expected_uri = "src/hello.sh",
    report = "machine_shellcheck_report",
)
