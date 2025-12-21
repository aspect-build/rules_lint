bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_shell_lints() {
	# Shellcheck
	echo <<"EOF" | assert_output --partial
In src/hello.sh line 3:
[ -z $THING ] && echo "hello world"
     ^----^ SC2086 (info): Double quote to prevent globbing and word splitting.
EOF
}

@test "should produce reports" {
	run $BATS_TEST_DIRNAME/../lint.sh //src:all --no@aspect_rules_lint//lint:color
	assert_success
	assert_shell_lints
}

@test "should fail when --fail-on-violation is passed" {
	run $BATS_TEST_DIRNAME/../lint.sh --fail-on-violation //src:all
	assert_failure
	assert_shell_lints
}

