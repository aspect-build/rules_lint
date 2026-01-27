bats_load_library "bats-support"
bats_load_library "bats-assert"

# Test syntactic mode - should catch DisableSyntax violations
@test "should produce syntactic lint reports with scalafix" {
	run bash -c "aspect lint -- //src:hello || true"
	assert_success

	# DisableSyntax.noVars should catch the var declaration
	assert_output --partial "DisableSyntax.var"
}

@test "should produce syntactic machine reports with scalafix" {
	run bash -c "aspect lint --config=lint -- //src:hello > \"$BATS_TEST_TMPDIR/lint.out\" || true"
	assert_success

	run cat bazel-bin/src/hello.AspectRulesLintScalafix.report
	assert_output --partial "DisableSyntax.var"
}

# Test semantic mode - should run OrganizeImports to reorganize imports
@test "should produce semantic lint reports with scalafix" {
	run bash -c "aspect lint --config=lint-semantic -- //src:semantic_test || true"
	assert_success

	# Check the output file for OrganizeImports suggested changes
	run cat bazel-bin/src/semantic_test.AspectRulesLintScalafix.out
	# OrganizeImports should suggest reordering imports (Future before Try alphabetically)
	assert_output --partial "import scala.concurrent.Future"
}

@test "should produce semantic machine reports with scalafix" {
	run bash -c "aspect lint --config=lint-semantic -- //src:semantic_test > \"$BATS_TEST_TMPDIR/lint.out\" || true"
	assert_success

	run cat bazel-bin/src/semantic_test.AspectRulesLintScalafix.report
	assert_output --partial "Scalafix rewrite suggested"
}
