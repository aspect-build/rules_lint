"Demonstrates how to enforce zero-lint-tolerance policy with tests"

# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "report_results_count_test", "report_test")
load("//tools/lint:linters.bzl", "fsharplint_test")
load(":machine_output.bzl", "machine_fsharplint_report")

fsharplint_test(
    name = "fsharplint",
    srcs = ["//src:record"],
    # FSharpLint exits -1 when it reports a warning
    expected_exit_code = 255,
)

fsharplint_test(
    name = "fsharplint_clean",
    srcs = ["//src:hello_fsharp"],
)

machine_fsharplint_report(
    name = "machine_fsharplint_report",
    src = "//src:record",
)

report_test(
    name = "fsharplint_machine_output_test",
    expected_tool = "FSharpLint",
    expected_uri = "src/record.fs",
    report = "machine_fsharplint_report",
)

report_results_count_test(
    name = "fsharplint_machine_output_count_test",
    expected_count = 2,
    report = "machine_fsharplint_report",
)
