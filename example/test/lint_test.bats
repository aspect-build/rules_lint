bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_lints() {
    # Shellcheck
    echo <<"EOF" | assert_output --partial
In src/hello.sh line 3:
[ -z $THING ] && echo "hello world"
     ^----^ SC2086 (info): Double quote to prevent globbing and word splitting.
EOF

    # Ruff
    echo <<"EOF" | assert_output --partial
src/unused_import.py:13:8: F401 [*] `os` imported but unused
Found 1 error.
[*] 1 fixable with the `--fix` option.
EOF

    # Flake8
    assert_output --partial "src/unused_import.py:13:1: F401 'os' imported but unused"

    # PMD
    assert_output --partial 'src/Foo.java:9:	FinalizeOverloaded:	Finalize methods should not be overloaded'

    # ESLint
    assert_output --partial 'src/file.ts:2:7: Type string trivially inferred from a string literal, remove type annotation  [error from @typescript-eslint/no-inferrable-types]'

    # Buf
    assert_output --partial 'src/file.proto:1:1:Import "src/unused.proto" is unused.'
}

@test "should produce reports" {
    run $BATS_TEST_DIRNAME/../lint.sh //src:all
    assert_success
    assert_lints
}

@test "should fail when --fail-on-violation is passed" {
    run $BATS_TEST_DIRNAME/../lint.sh --fail-on-violation //src:all
    assert_failure
    assert_lints
}

@test "should use nearest ancestor .eslintrc file" {
    run $BATS_TEST_DIRNAME/../lint.sh //src/subdir:eslint-override
    assert_success
    refute_output --partial "Unexpected 'debugger' statement"
}