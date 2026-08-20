load("//tools/lint:linters.bzl", "ps_script_analyzer_test")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "scripts",
    srcs = glob(["**/*.ps1"]),
    tags = ["lint-with-psscriptanalyzer"],
)

filegroup(
    name = "clean_scripts",
    srcs = ["hello.ps1"],
    tags = ["lint-with-psscriptanalyzer"],
)

# bad.ps1 triggers violations — expect exit code 1
ps_script_analyzer_test(
    name = "ps_script_analyzer_violations_test",
    srcs = [":scripts"],
    expected_exit_code = 1,
)

# hello.ps1 is clean — expect exit code 0, empty output, empty SARIF
ps_script_analyzer_test(
    name = "ps_script_analyzer_clean_test",
    srcs = [":clean_scripts"],
    expected_exit_code = 0,
)
