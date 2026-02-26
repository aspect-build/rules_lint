"Demonstrates how to enforce zero-lint-tolerance policy with tests"

# buildifier: disable=bzl-visibility
load("@aspect_rules_lint//lint/private:machine_report_testing.bzl", "report_test")  # @unused: used in commented-out tests
load(
    "//tools/lint:linters.bzl",
    "clang_tidy_test",
    "cppcheck_test",
)
load(
    ":machine_output.bzl",
    "machine_clang_tidy_report",
    "machine_cppcheck_report",
)

clang_tidy_test(
    name = "clang_tidy",
    srcs = ["//src:hello_cc"],
    expected_exit_code = 1,
)

cppcheck_test(
    name = "cppcheck",
    srcs = ["//src:hello_cc"],
    expected_exit_code = 31,
)

machine_clang_tidy_report(
    name = "machine_clang_tidy_report",
    src = "//src:hello_cc",
)

# FIXME: I'm getting a C++ compile failure on macos
# report_test(
#     name = "clang_tidy_machine_output_test",
#     report = "machine_clang_tidy_report",
#     expected_tool = "ClangTidy",
#     expected_uri = "src/hello.cpp",
# )

machine_cppcheck_report(
    name = "machine_cppcheck_report",
    src = "//src:hello_cc",
)

# report_test(
#     name = "cppcheck_machine_output_test",
#     report = "machine_cppcheck_report",
#     expected_tool = "Cppcheck",
#     expected_uri = "src/hello.cpp",
# )
