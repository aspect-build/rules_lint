bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_java_lints() {
	# PMD
	echo <<"EOF" | assert_output --partial
* file: src/Foo.java
    src:  Foo.java:9:9
    rule: FinalizeOverloaded
    msg:  Finalize methods should not be overloaded
    code: protected void finalize(int a) {}
EOF
}

@test "should produce reports" {
	run $BATS_TEST_DIRNAME/../lint.sh //src:all --no@aspect_rules_lint//lint:color
	assert_success
	assert_java_lints
}

@test "should fail when --fail-on-violation is passed" {
	run $BATS_TEST_DIRNAME/../lint.sh --fail-on-violation //src:all
	assert_failure
	assert_java_lints
}

