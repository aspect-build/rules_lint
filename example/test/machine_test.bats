# Test machine-readable output groups
bats_load_library "bats-support"
bats_load_library "bats-assert"

@test "should get SARIF output from ruff" {
	run bazel build --aspects=//tools/lint:linters.bzl%ruff --output_groups=rules_lint_machine //src:unused_import
	run jq '.runs[].tool.driver.name' bazel-bin/src/unused_import.AspectRulesLintRuff.report
    assert_output "ruff"
}

@test "should get SARIF output from shellcheck" {
	run bazel build --aspects=//tools/lint:linters.bzl%shellcheck --output_groups=rules_lint_machine //src:hello_shell
	run jq '.runs[].tool.driver.name' bazel-bin/src/hello_shell.AspectRulesLintShellcheck.report
    assert_output "shellcheck"
}

@test "should get SARIF output from ESLint" {
	run bazel build --aspects=//tools/lint:linters.bzl%eslint --output_groups=rules_lint_machine //src:ts_typings
	run jq '.runs[].tool.driver.name' bazel-bin/src/ts_typings.AspectRulesLintESLint.report
    assert_output "eslint"
}

@test "should get SARIF output from spotbugs" {
	run bazel build --aspects=//tools/lint:linters.bzl%spotbugs --output_groups=rules_lint_machine //src:foo
	run jq '.runs[].tool.driver.name' bazel-bin/src/foo.AspectRulesLintSpotbugs.report
    assert_output "spotbugs"
}

@test "should get SARIF output from stylelint" {
	run bazel build --aspects=//tools/lint:linters.bzl%stylelint --output_groups=rules_lint_machine //src:css
	run jq '.runs[].tool.driver.name' bazel-bin/src/css.AspectRulesLintStylelint.report
    assert_output "stylelint"
}

@test "should get SARIF output from vale" {
	run bazel build --aspects=//tools/lint:linters.bzl%vale --output_groups=rules_lint_machine //src:md
	run jq '.runs[].tool.driver.name' bazel-bin/src/md.AspectRulesLintVale.report
    assert_output "vale"
}

@test "should get SARIF output from clang_tidy" {
	run bazel build --aspects=//tools/lint:linters.bzl%clang_tidy --output_groups=rules_lint_machine //src:hello_cc
	run jq '.runs[].tool.driver.name' bazel-bin/src/cc.AspectRulesLintClangTidy.report
    assert_output "clang_tidy"
}

@test "should get SARIF output from buf" {
    run bazel build --aspects=//tools/lint:linters.bzl%buf --output_groups=rules_lint_machine //src:proto
    run jq '.runs[].tool.driver.name' bazel-bin/src/unused.AspectRulesLintBuf.report
    assert_output "buf"
}

@test "should get SARIF output from keep_sorted" {
    run bazel build --aspects=//tools/lint:linters.bzl%keep_sorted --output_groups=rules_lint_machine //src:keep_sorted
    run jq '.runs[].tool.driver.name' bazel-bin/src/keep_sorted.AspectRulesLintKeepSorted.report
    assert_output "keep_sorted"
}

@test "should get SARIF output from ktlint" {
    run bazel build --aspects=//tools/lint:linters.bzl%ktlint --output_groups=rules_lint_machine //src:ktlint
    run jq '.runs[].tool.driver.name' bazel-bin/src/ktlint.AspectRulesLintKtlint.report
    assert_output "ktlint"
}

@test "should get SARIF output from pmd" {
    run bazel build --aspects=//tools/lint:linters.bzl%pmd --output_groups=rules_lint_machine //src:pmd
    run jq '.runs[].tool.driver.name' bazel-bin/src/pmd.AspectRulesLintPmd.report
    assert_output "pmd"
} 

@test "should get SARIF output from spotbugs" {
    run bazel build --aspects=//tools/lint:linters.bzl%spotbugs --output_groups=rules_lint_machine //src:foo
    run jq '.runs[].tool.driver.name' bazel-bin/src/foo.AspectRulesLintSpotbugs.report
    assert_output "spotbugs"
}

@test "should get SARIF output from flake8" {
    run bazel build --aspects=//tools/lint:linters.bzl%flake8 --output_groups=rules_lint_machine //src:flake8
    run jq '.runs[].tool.driver.name' bazel-bin/src/unused_import.AspectRulesLintFlake8.report
    assert_output "flake8"
}
