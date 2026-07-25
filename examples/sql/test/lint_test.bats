bats_load_library "bats-support"
bats_load_library "bats-assert"

@test "should produce SQLFluff reports" {
	run aspect lint --strategy=soft --tips:silence=add-aspect-api-token-github-actions -- //src/...
	assert_success
	assert_output --partial "src/hello.sql:1"
	assert_output --partial "CP01: Keywords must be upper case."
	refute_output --partial "All Finished"
}

@test "should pass the SQLFluff Bazel tests" {
	run bazel test //:requirements.test //test/...
	assert_success
}

@test "should produce an applicable SQLFluff fix patch" {
	run bazel build --config=lint --output_groups=rules_lint_patch --@aspect_rules_lint//lint:fix //src:query_template //src:clean
	assert_success

	run test -s bazel-bin/src/query_template.AspectRulesLintSQLFluff.patch
	assert_success
	run git apply --check bazel-bin/src/query_template.AspectRulesLintSQLFluff.patch
	assert_success

	run test ! -s bazel-bin/src/clean.AspectRulesLintSQLFluff.patch
	assert_success
}

@test "should fail a hard lint build on SQLFluff findings" {
	run bazel build --config=lint --output_groups=rules_lint_human --@aspect_rules_lint//lint:fail_on_violation //src:hello
	assert_failure
}

@test "should check SQL formatting with SQLFluff" {
	run bazel run //tools/format:format_SQL_with_sqlfluff.check -- src/clean.dml
	assert_success

	run bazel run //tools/format:format_SQL_with_sqlfluff.check -- src/hello.sql
	assert_failure
	assert_output --partial "CP01"
}
