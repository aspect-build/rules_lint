bats_load_library "bats-support"
bats_load_library "bats-assert"

@test "should format and check SQL with SQLFluff" {
	run bazel run //tools/format:format_SQL_with_sqlfluff -- src/clean.dml
	assert_success
	refute_output --partial "All Finished"

	run bazel run //tools/format:format_SQL_with_sqlfluff.check -- src/clean.dml
	assert_success
	refute_output --partial "All Finished"

	run bazel run //tools/format:format_SQL_with_sqlfluff.check -- src/hello.sql
	assert_failure
	assert_output --partial "CP01"
	refute_output --partial "All Finished"
}
