# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "PHYSICAL_ARTIFACT_LOCATION_URI_FILTER")
load("@jq.bzl//jq:jq.bzl", "jq_test")
load("//test:machine_output.bzl", "machine_tflint_report")
load("//tools/lint:linters.bzl", "tflint_test")

package(default_visibility = ["//visibility:public"])

tflint_test(
    name = "tflint",
    srcs = ["//src:example"],
    expected_exit_code = 2,
)

machine_tflint_report(
    name = "machine_tflint_report",
    src = "//src:example",
)

# tflint's native SARIF includes multiple runs (one per ruleset plus a
# "tflint-errors" run for internal errors), so we check .runs[0] rather
# than .runs[] for the tool name.
jq_test(
    name = "tflint_machine_output_test",
    file1 = "machine_tflint_report",
    file2 = "machine_tflint_report",
    filter1 = ".runs[0].tool.driver.name",
    filter2 = "\"tflint\"",
)

jq_test(
    name = "tflint_machine_output_test_uri",
    file1 = "machine_tflint_report",
    file2 = "machine_tflint_report",
    filter1 = PHYSICAL_ARTIFACT_LOCATION_URI_FILTER,
    filter2 = "\"src/main.tf\"",
)
