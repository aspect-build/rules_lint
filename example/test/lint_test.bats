bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_lints() {
	# Ruff
	echo <<"EOF" | assert_output --partial
src/unused_import.py:18:8: F401 [*] `os` imported but unused
Found 2 errors.
[*] 1 fixable with the `--fix` option.
EOF

	# pylint
	echo <<"EOF" | assert_output --partial
src/unused_import.py:15:0: C0301: Line too long (180/120) (line-too-long)
src/unused_import.py:22:6: W1302: Invalid format string (bad-format-string)
src/unused_import.py:18:0: W0611: Unused import os (unused-import)
EOF

	# Ty
	echo <<"EOF" | assert_output --partial
error[unsupported-operator]: Operator `+` is unsupported between objects of type `Literal[10]` and `Literal["test"]`
 --> src/unsupported_operator.py:3:5
  |
1 | # Demo with just running ty from the examples dir:
2 | # $ ./lint.sh src:unsupported_operator
3 | a = 10 + "test"
  |     ^^^^^^^^^^^
  |
info: rule `unsupported-operator` is enabled by default

Found 1 diagnostic
EOF

	# pylint
	echo <<"EOF" | assert_output --partial
src/unused_import.py:15:0: C0301: Line too long (180/120) (line-too-long)
src/unused_import.py:22:6: W1302: Invalid format string (bad-format-string)
src/unused_import.py:18:0: W0611: Unused import os (unused-import)
EOF

	# Flake8
	assert_output --partial "src/unused_import.py:18:1: F401 'os' imported but unused"

	# PMD
	echo <<"EOF" | assert_output --partial
* file: src/Foo.java
    src:  Foo.java:9:9
    rule: FinalizeOverloaded
    msg:  Finalize methods should not be overloaded
    code: protected void finalize(int a) {}
EOF

	# ktlint
	assert_output --partial "src/hello.kt:1:1: File name 'hello.kt' should conform PascalCase (standard:filename)"

	# Vale
	echo <<"EOF" | assert_output --partial
3:47  warning  Try to avoid using              Google.We
               first-person plural like 'We'.
EOF

	# RuboCop
	echo <<"EOF" | assert_output --partial
C:  1:  1: [Correctable] Style/FrozenStringLiteralComment: Missing frozen string literal comment.
W:  4:  1: [Correctable] Lint/UselessAssignment: Useless assignment to variable - unused_variable.
C:  6:101: Layout/LineLength: Line is too long. [115/100]
EOF

	# Standard Ruby
	echo <<"EOF" | assert_output --partial
== src/hello.rb ==
W:  4:  1: [Correctable] Lint/UselessAssignment: Useless assignment to variable - unused_variable.
C: 19:  3: [Correctable] Layout/IndentationWidth: Use 2 (not 4) spaces for indentation.
W: 29:  1: [Correctable] Lint/UselessAssignment: Useless assignment to variable - message.
W: 32:  1: [Correctable] Lint/UselessAssignment: Useless assignment to variable - numbers.
EOF

}

@test "should produce reports" {
	run $BATS_TEST_DIRNAME/../lint.sh //src:all --no@aspect_rules_lint//lint:color
	assert_success
	assert_lints

	run $BATS_TEST_DIRNAME/../lint.sh --fix --dry-run //src:all
	assert_success

	# Check that we created a 'patch -p1' format file that fixes the ruff violation
	run cat bazel-bin/src/unused_import.AspectRulesLintRuff.patch
	assert_success
	echo <<"EOF" | assert_output --partial
--- a/src/unused_import.py
+++ b/src/unused_import.py
@@ -15,7 +15,6 @@
 # $ bazel run --run_under="cd $PWD &&" -- //tools/lint:pylint --rcfile=.pylintrc --reports=n --score=n --msg-template="{path}:{line}:{column}: {msg_id}: {msg}" src/unused_import.py
 # src/unused_import.py:22:6: W1302: Invalid format string
 # src/unused_import.py:18:0: W0611: Unused import os
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

@test "stylelint should produce output even with no violations" {
	assert_success
	# The exit code should be 0 (no violations)
	run cat bazel-bin/src/clean_css.AspectRulesLintStylelint.out.exit_code
	assert_output "0"
}

@test "stylelint should capture violations in output" {
	assert_success
	# Verify the violation is captured in the output
	run cat bazel-bin/src/css.AspectRulesLintStylelint.out
	assert_output --partial "Unexpected empty block"
	assert_output --partial "block-no-empty"
}
