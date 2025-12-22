bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_kotlin_lints() {
	# ktlint
	assert_output --partial "ktlint"
}

@test "should produce reports" {
	run aspect lint //src:all
	assert_success
	assert_kotlin_lints
}

@test "should fail when --fail-on-violation is passed" {
	run aspect lint --fail-on-violation //src:all
	assert_failure
	assert_kotlin_lints
}

