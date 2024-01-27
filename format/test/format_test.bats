# Simple test fixture that uses this "real" git repository.
# Ideally we would create self-contained "system under test" for each test case.
# That would let us test more scenarios with git, like deleted files.
bats_load_library "bats-support"
bats_load_library "bats-assert"

# No arguments: will use git ls-files
@test "should run prettier on javascript using git ls-files" {
    run bazel run //format/test:format_javascript
    assert_success
    
    assert_output --partial "Formatting JavaScript with Prettier..."
    assert_output --partial "+ prettier --write example/.eslintrc.cjs"
    assert_output --partial "Formatting TypeScript with Prettier..."
    assert_output --partial "+ prettier --write example/src/file.ts example/test/no_violations.ts"
    assert_output --partial "Formatting TSX with Prettier..."
    assert_output --partial "+ prettier --write example/src/hello.tsx"
}

# File arguments: will filter with find
@test "should run prettier on javascript using find" {
    run bazel run //format/test:format_javascript README.md example/.eslintrc.cjs
    assert_success

    assert_output --partial "Formatting JavaScript with Prettier..."
    refute_output --partial "Formatting TypeScript with Prettier..."
}

@test "should run buildozer on starlark" {
    run bazel run //format/test:format_starlark
    assert_success

    assert_output --partial "Formatting Starlark with Buildifier..."
    assert_output --partial "+ buildifier -mode=fix BUILD.bazel"
    # FIXME(#122): this was broken by #105
    # assert_output --partial "format/private/BUILD.bazel"
}
