bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_kotlin_lints() {
	echo <<"EOF" | assert_output --partial
src/hello.kt:1:1: File name 'hello.kt' should conform PascalCase (standard:filename)
src/hello.kt:2:1: Wildcard import (standard:no-wildcard-imports)
EOF
}

@test "should produce reports" {
	run aspect lint --bazel-flag=--config=lint --bazel-flag=--output_groups=rules_lint_human -- //src/...
	assert_success
	assert_kotlin_lints
}
