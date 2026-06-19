# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "report_test")
load("//test:machine_output.bzl", "machine_biome_report", "machine_eslint_report", "machine_stylelint_report")
load("//tools/lint:linters.bzl", "biome_test", "eslint_test", "stylelint_test")

biome_test(
    name = "biome",
    srcs = ["//src:biome_bad"],
    expected_exit_code = 1,
)

biome_test(
    name = "biome_no_violations",
    srcs = ["//src:biome_clean"],
)

eslint_test(
    name = "eslint_empty_report",
    srcs = ["//src:ts"],
)

stylelint_test(
    name = "stylelint_no_violations",
    srcs = ["//src:clean_css"],
)

machine_biome_report(
    name = "machine_biome_report",
    src = "//src:biome_bad",
)

report_test(
    name = "biome_machine_output_test",
    expected_tool = "Biome",
    expected_uri = "src/biome_bad.ts",
    report = "machine_biome_report",
)

machine_eslint_report(
    name = "machine_eslint_report",
    src = "//src:ts",
)

report_test(
    name = "eslint_machine_output_test",
    expected_tool = "ESLint",
    expected_uri = "src/file.ts",
    report = "machine_eslint_report",
)

machine_stylelint_report(
    name = "machine_stylelint_report",
    src = "//src:css",
)

report_test(
    name = "stylelint_machine_output_test",
    expected_tool = "Stylelint",
    expected_uri = "src/hello.css",
    report = "machine_stylelint_report",
)
