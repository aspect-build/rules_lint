# Test machine-readable output groups
# NB: there are also tests in the Go code to assert that each language parser does the right thing.
bats_load_library "bats-support"
bats_load_library "bats-assert"

# This variable will be set by each test
REPORT_FILE=""
SARIF_TOOL_DRIVER_NAME_FILTER='.runs[].tool.driver.name' 
PHYSICAL_ARTIFACT_LOCATION_URI_FILTER='.runs[].results | map(.locations | map(.physicalLocation.artifactLocation.uri)) | flatten | unique[]'

teardown() {
  if [[ "$status" -ne 0 && -n "$REPORT_FILE" && -f "$REPORT_FILE" ]]; then
    echo
    echo "-- actual report content --"
    cat "$REPORT_FILE"
    echo "--"
  fi
}

function run_lint() {
    linter=$1
    target=$2
    run bazel build "--aspects=//tools/lint:linters.bzl%$linter" --output_groups=rules_lint_machine "//src:$target"
    assert_success
}

function assert_driver_name() {
    run jq --raw-output "$SARIF_TOOL_DRIVER_NAME_FILTER" $REPORT_FILE
    assert_output "$1"
}

function assert_physical_artifact_location_uri() {
    run jq --raw-output "$PHYSICAL_ARTIFACT_LOCATION_URI_FILTER" $REPORT_FILE
    assert_output "$1"
}

@test "should get SARIF output from shellcheck" {
	run_lint shellcheck hello_shell
    REPORT_FILE=bazel-bin/src/hello_shell.AspectRulesLintShellCheck.report
    assert_driver_name "ShellCheck"
    assert_physical_artifact_location_uri "src/hello.sh"
}

@test "should get SARIF output from ruff" {
    run_lint ruff unused_import
    REPORT_FILE=bazel-bin/src/unused_import.AspectRulesLintRuff.report
    assert_driver_name "Ruff"
    assert_physical_artifact_location_uri "src/unused_import.py"
}

@test "should get SARIF output from ESLint" {
    run_lint eslint ts_typings
    REPORT_FILE=bazel-bin/src/ts_typings.AspectRulesLintESLint.report
    assert_driver_name "ESLint"
    assert_physical_artifact_location_uri "src/file.ts"
}

# @test "should get SARIF output from spotbugs" {
#     run_lint spotbugs foo
# 	run jq '.runs[].tool.driver.name' bazel-bin/src/foo.AspectRulesLintSpotbugs.report
#     assert_output "spotbugs"
# }

# @test "should get SARIF output from stylelint" {
#     run_lint stylelint css
# 	run jq '.runs[].tool.driver.name' bazel-bin/src/css.AspectRulesLintStylelint.report
#     assert_output "stylelint"
# }

# @test "should get SARIF output from vale" {
#     run_lint vale md
# 	run jq '.runs[].tool.driver.name' bazel-bin/src/md.AspectRulesLintVale.report
#     assert_output "vale"
# }

# @test "should get SARIF output from clang_tidy" {
#     run_lint clang_tidy hello_cc
# 	run jq '.runs[].tool.driver.name' bazel-bin/src/cc.AspectRulesLintClangTidy.report
#     assert_output "clang_tidy"
# }

# @test "should get SARIF output from buf" {
#     run_lint buf proto
#     run jq '.runs[].tool.driver.name' bazel-bin/src/unused.AspectRulesLintBuf.report
#     assert_output "buf"
# }

# @test "should get SARIF output from keep_sorted" {
#     run_lint keep_sorted keep_sorted
#     run jq '.runs[].tool.driver.name' bazel-bin/src/keep_sorted.AspectRulesLintKeepSorted.report
#     assert_output "keep_sorted"
# }

# @test "should get SARIF output from ktlint" {
#     run_lint ktlint hello_kt
#     run jq '.runs[].tool.driver.name' bazel-bin/src/hello_kt.AspectRulesLintKtlint.report
#     assert_output "ktlint"
# }

# @test "should get SARIF output from pmd" {
#     run_lint pmd foo
#     run jq '.runs[].tool.driver.name' bazel-bin/src/foo.AspectRulesLintPmd.report
#     assert_output "pmd"
# }

# @test "should get SARIF output from flake8" {
#     run_lint flake8 unused_import
#     run jq '.runs[].tool.driver.name' bazel-bin/src/unused_import.AspectRulesLintFlake8.report
#     assert_output "flake8"
# }
