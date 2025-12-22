bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_kotlin_lints() {
	echo <<"EOF" | assert_output --partial
src/hello.kt:1:1: File name 'hello.kt' should conform PascalCase (standard:filename)
src/hello.kt:2:1: Wildcard import (standard:no-wildcard-imports)
EOF
}

@test "should produce reports" {
	run aspect lint //src:all
	assert_success
	assert_kotlin_lints
}

@test "should fail when fail_on_violation is passed" {
	run bazel build --@aspect_rules_lint//lint:fail_on_violation //src:all
	assert_failure
	assert_kotlin_lints
}
