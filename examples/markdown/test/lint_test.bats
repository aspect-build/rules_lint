bats_load_library "bats-support"
bats_load_library "bats-assert"

@test "should report broken local links" {
	run aspect lint --strategy=soft --tips:silence=add-aspect-api-token-github-actions -- //src:bad
	assert_success
	assert_output --partial "MD051"
	assert_output --partial "MD057"
	assert_output --partial "src/bad.md"
	refute_output --partial "/execroot/"
	refute_output --partial "/sandbox/"
}
