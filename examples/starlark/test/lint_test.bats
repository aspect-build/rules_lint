bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_starlark_lints() {
	echo <<"EOF" | assert_output --partial
src/defs.bzl:5: list-append: Prefer using ".append()" to adding a single element list.
EOF

	echo <<"EOF" | assert_output --partial
src/custom.star:5: list-append: Prefer using ".append()" to adding a single element list.
EOF
}

@test "should produce reports" {
	run aspect lint //src:defs //src:tagged_starlark
	assert_success
	assert_starlark_lints
}
