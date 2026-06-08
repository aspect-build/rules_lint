bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_cpp_lints() {
	# clang-tidy
	assert_output --partial "clang-tidy"
	# cppcheck
	assert_output --partial "cppcheck"
}

@test "should produce reports" {
	run aspect lint --bazel-flag=--config=lint -- //src/...
	assert_success
	assert_cpp_lints
}

# Regression for https://github.com/aspect-build/rules_lint/issues/899: clang-tidy
# prints summary statistics ("N warnings generated.", "Suppressed N warnings (...)")
# even on clean code; left in the report they trip --@aspect_rules_lint//lint:fail_on_violation.
@test "clang-tidy report excludes summary statistics" {
	bazel build --aspects=//tools/lint:linters.bzl%clang_tidy --output_groups=rules_lint_human //src:hello_cc
	report=$(find -L "$(bazel info bazel-bin)/src" -name '*hello*ClangTidy*.out' | head -n 1)
	run cat "$report"
	assert_success
	# real diagnostics survive, summary statistics are filtered out
	assert_output --partial "warning:"
	refute_output --partial "warnings generated"
	refute_output --partial "Suppressed"
}
