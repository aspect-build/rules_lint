bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_cpp_lints() {
	# clang-tidy
	assert_output --partial "clang-tidy"
	# cppcheck
	assert_output --partial "cppcheck"
}

@test "should produce reports" {
	run aspect lint //src:all --no@aspect_rules_lint//lint:color
	assert_success
	assert_cpp_lints
}

@test "should fail when --fail-on-violation is passed" {
	run aspect lint --fail-on-violation //src:all
	assert_failure
	assert_cpp_lints
}

