# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "report_results_count_test", "report_test")
load("@jq.bzl//jq:jq.bzl", "jq_test")
load("//test:machine_output.bzl", "machine_sqlfluff_report")
load("//tools/lint:linters.bzl", "sqlfluff_test")

package(default_visibility = ["//visibility:public"])

sqlfluff_test(
    name = "sqlfluff_reports_findings",
    srcs = ["//src:hello"],
    expected_exit_code = 1,
)

sqlfluff_test(
    name = "sqlfluff_lints_sql_j2_files",
    srcs = ["//src:query_template"],
    expected_exit_code = 1,
)

sqlfluff_test(
    name = "sqlfluff_accepts_clean_sql",
    srcs = ["//src:clean"],
)

sqlfluff_test(
    name = "sqlfluff_discovers_nested_configs_with_target_data",
    srcs = ["//src:mixed_configs_with_target_data"],
)

sqlfluff_test(
    name = "sqlfluff_does_not_share_target_data",
    srcs = ["//src:template_without_data"],
    expected_exit_code = 1,
)

machine_sqlfluff_report(
    name = "sqlfluff_missing_target_data_machine_report",
    src = "//src:template_without_data",
)

report_test(
    name = "sqlfluff_missing_target_data_machine_report_test",
    expected_tool = "SQLFluff",
    expected_uri = "src/macro_query.sql.j2",
    report = "sqlfluff_missing_target_data_machine_report",
)

jq_test(
    name = "sqlfluff_missing_target_data_reports_templating_error_test",
    file1 = "sqlfluff_missing_target_data_machine_report",
    file2 = "sqlfluff_missing_target_data_machine_report",
    filter1 = ".runs[].results[].ruleId",
    filter2 = "\"TMP\"",
)

machine_sqlfluff_report(
    name = "machine_sqlfluff_report",
    src = "//src:hello",
)

report_test(
    name = "sqlfluff_machine_output_test",
    expected_tool = "SQLFluff",
    expected_uri = "src/hello.sql",
    report = "machine_sqlfluff_report",
)

jq_test(
    name = "sqlfluff_machine_output_omits_timestamps_test",
    file1 = "machine_sqlfluff_report",
    file2 = "machine_sqlfluff_report",
    filter1 = "[.. | objects | select(has(\"endTimeUtc\") or has(\"startTimeUtc\"))] | length",
    filter2 = "0",
)

machine_sqlfluff_report(
    name = "machine_sqlfluff_clean_report",
    src = "//src:clean",
)

report_results_count_test(
    name = "sqlfluff_clean_machine_output_empty_test",
    expected_count = 0,
    report = "machine_sqlfluff_clean_report",
)

machine_sqlfluff_report(
    name = "sqlfluff_mixed_configs_machine_report",
    src = "//src:mixed_configs_with_target_data",
)

report_results_count_test(
    name = "sqlfluff_mixed_configs_machine_report_empty_test",
    expected_count = 0,
    report = "sqlfluff_mixed_configs_machine_report",
)

machine_sqlfluff_report(
    name = "machine_sqlfluff_template_report",
    src = "//src:query_template",
)

report_test(
    name = "sqlfluff_template_machine_output_test",
    expected_tool = "SQLFluff",
    expected_uri = "src/query.sql.j2",
    report = "machine_sqlfluff_template_report",
)

report_results_count_test(
    name = "sqlfluff_template_machine_results_count_test",
    expected_count = 2,
    report = "machine_sqlfluff_template_report",
)
