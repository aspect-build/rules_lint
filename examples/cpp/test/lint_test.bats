bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_cpp_lints() {
	# clang-tidy
	assert_output --partial "clang-tidy"
	# cppcheck
	assert_output --partial "cppcheck"
}

@test "should produce reports" {
	run aspect lint //src:all
	assert_success
	assert_cpp_lints
}
