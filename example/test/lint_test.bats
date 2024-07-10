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

	# ktlint
	assert_output --partial "src/hello.kt:1:1: File name 'hello.kt' should conform PascalCase (standard:filename)"

	# ESLint
	assert_output --partial 'src/file.ts: line 2, col 7, Error - Type string trivially inferred from a string literal, remove type annotation. (@typescript-eslint/no-inferrable-types)'

	# Buf
	assert_output --partial 'src/file.proto:3:1:Import "src/unused.proto" is unused.'

	# Vale
	assert_output --partial "src/README.md:3:47:Google.We:Try to avoid using first-person plural like 'We'."
}

@test "should produce reports" {
	run $BATS_TEST_DIRNAME/../lint.sh //src:all
	assert_success
	assert_lints

	run $BATS_TEST_DIRNAME/../lint.sh --fix --dry-run //src:all
	assert_success

	# Check that we created a 'patch -p1' format file that fixes the ESLint violation
	run cat bazel-bin/src/ts.AspectRulesLintESLint.patch
	assert_success
	echo <<"EOF" | assert_output --partial
--- a/src/file.ts
+++ b/src/file.ts
@@ -1,3 +1,3 @@
 // this is a linting violation
-const a: string = "a";
+const a = "a";
 console.log(a);
EOF

	# Check that we created a 'patch -p1' format file that fixes the ruff violation
	run cat bazel-bin/src/unused_import.AspectRulesLintRuff.patch
	assert_success
	echo <<"EOF" | assert_output --partial
--- a/src/unused_import.py
+++ b/src/unused_import.py
@@ -10,4 +10,3 @@
 # src/unused_import.py:12:8: F401 [*] `os` imported but unused
 # Found 1 error.
 # [*] 1 potentially fixable with the --fix option.
-import os
EOF
}

@test "should fail when --fail-on-violation is passed" {
	run $BATS_TEST_DIRNAME/../lint.sh --fail-on-violation //src:all
	assert_failure
	assert_lints
}

@test "should use nearest ancestor .eslintrc file" {
	run $BATS_TEST_DIRNAME/../lint.sh //src/subdir:eslint-override
	assert_success
	# This lint check is disabled in the .eslintrc.cjs file
	refute_output --partial "Unexpected 'debugger' statement"
}
