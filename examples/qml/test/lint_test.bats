bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_qml_lints() {
	echo <<"EOF" | assert_output --partial
Main.qml:2:1:
Unused import [unused-imports]
EOF
}

@test "should produce reports" {
	run aspect lint --bazel-flag=--config=lint --bazel-flag=--output_groups=rules_lint_human -- //src/...
	assert_success
	assert_qml_lints
}
