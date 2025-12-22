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
	run aspect lint //src:all
	assert_success
	assert_shell_lints
}
