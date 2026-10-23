bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_fsharp_lints() {
	assert_output --partial "Consider changing \`name\` to PascalCase."
	assert_output --partial "\`not true\` might be able to be refactored into \`false\`."
	refute_output --partial "Going to analyze single .fs file"
}

@test "should produce reports" {
	run aspect lint $REMOTE_FLAG --strategy=soft --tips:silence=add-aspect-api-token-github-actions -- //src/...
	assert_success
	assert_fsharp_lints
}
