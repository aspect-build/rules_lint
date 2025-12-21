bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_kotlin_lints() {
	# ktlint
	assert_output --partial "ktlint"
}

@test "should produce reports" {
	run $BATS_TEST_DIRNAME/../lint.sh //src:all --no@aspect_rules_lint//lint:color
	assert_success
	assert_kotlin_lints
}

@test "should fail when --fail-on-violation is passed" {
	run $BATS_TEST_DIRNAME/../lint.sh --fail-on-violation //src:all
	assert_failure
	assert_kotlin_lints
}

