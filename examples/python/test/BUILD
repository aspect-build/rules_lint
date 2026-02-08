"Demonstrates how to enforce zero-lint-tolerance policy with tests"

# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "report_test")  # @unused: used in commented-out tests
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_python//python:defs.bzl", "py_library")
load(
    "//tools/lint:linters.bzl",
    "bandit_test",
    "flake8_test",
    "pylint_test",
    "ruff_test",
    "ty_test",
)
load(
    ":machine_output.bzl",
    "machine_bandit_report",
    "machine_flake8_report",
    "machine_pylint_report",
    "machine_ruff_report",
    "machine_ty_report",
)

write_file(
    name = "py_code_generator",
    out = "generated.py",
    content = ["import os"],
)

py_library(
    name = "generated_py",
    srcs = ["generated.py"],
)

filegroup(
    name = "generated_py_filegroup",
    srcs = ["generated.py"],
    tags = [
        "lint-with-pylint",
        "lint-with-ruff",
    ],
)

py_library(
    name = "excluded_py",
    srcs = ["excluded.py"],
)

flake8_test(
    name = "flake8_should_ignore_generated",
    srcs = [":generated_py"],
)

pylint_test(
    name = "pylint_should_ignore_generated",
    srcs = [":generated_py"],
)

ruff_test(
    name = "ruff_should_ignore_generated",
    srcs = [":generated_py"],
)

ruff_test(
    name = "ruff_should_ignore_generated_filegroup",
    srcs = [":generated_py_filegroup"],
)

pylint_test(
    name = "pylint_should_ignore_generated_filegroup",
    srcs = [":generated_py_filegroup"],
)

ruff_test(
    name = "ruff_should_ignore_excluded",
    srcs = [":excluded_py"],
)

bandit_test(
    name = "bandit",
    srcs = ["//src:uses_eval"],
    expected_exit_code = 1,
)

flake8_test(
    name = "flake8",
    srcs = ["//src:unused_import"],
    expected_exit_code = 1,
)

pylint_test(
    name = "pylint",
    srcs = ["//src:unused_import"],
    expected_exit_code = 1,
)

ty_test(
    name = "ty_should_fail_unsupported_operator",
    srcs = ["//src:unsupported_operator"],
    expected_exit_code = 1,
)

machine_bandit_report(
    name = "machine_bandit_report",
    src = "//src:uses_eval",
)

report_test(
    name = "bandit_machine_output_test",
    expected_tool = "Bandit",
    expected_uri = "src/uses_eval.py",
    report = "machine_bandit_report",
)

machine_ruff_report(
    name = "machine_ruff_report",
    src = "//src:unused_import",
)

report_test(
    name = "ruff_machine_output_test",
    expected_tool = "Ruff",
    expected_uri = "src/unused_import.py",
    report = "machine_ruff_report",
)

machine_ruff_report(
    name = "machine_ruff_pyi_report",
    src = "//src:unused_import_pyi",
)

report_test(
    name = "ruff_pyi_machine_output_test",
    expected_tool = "Ruff",
    expected_uri = "src/unused_import.pyi",
    report = "machine_ruff_pyi_report",
)

machine_ty_report(
    name = "machine_ty_report",
    src = "//src:unsupported_operator",
)

report_test(
    name = "ty_machine_output_test",
    expected_tool = "Ty",
    expected_uri = "src/unsupported_operator.py",
    report = "machine_ty_report",
)

machine_flake8_report(
    name = "machine_flake8_report",
    src = "//src:unused_import",
)

report_test(
    name = "flake8_machine_output_test",
    expected_tool = "Flake8",
    expected_uri = "src/unused_import.py",
    report = "machine_flake8_report",
)

machine_pylint_report(
    name = "machine_pylint_report",
    src = "//src:unused_import",
)

report_test(
    name = "pylint_machine_output_test",
    expected_tool = "Pylint",
    expected_uri = "src/unused_import.py",
    report = "machine_pylint_report",
)
