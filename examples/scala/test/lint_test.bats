bats_load_library "bats-support"
bats_load_library "bats-assert"

# Test syntactic mode - should catch DisableSyntax violations
@test "should produce syntactic lint reports with scalafix" {
	run bazel build //src:hello \
		--aspects=//tools/lint:linters.bzl%scalafix \
		--output_groups=rules_lint_human
	assert_success

	# Check the output file for DisableSyntax violations
	run cat bazel-bin/src/hello.AspectRulesLintScalafix.out
	# DisableSyntax.noVars should catch the var declaration
	assert_output --partial "var"
}

# Test semantic mode - should run OrganizeImports to reorganize imports
@test "should produce semantic lint reports with scalafix" {
	run bazel build //src:semantic_test \
		--aspects=//tools/lint:linters.bzl%scalafix_semantic \
		--output_groups=rules_lint_human
	assert_success

	# Check the output file for OrganizeImports suggested changes
	run cat bazel-bin/src/semantic_test.AspectRulesLintScalafix.out
	# OrganizeImports should suggest reordering imports (Future before Try alphabetically)
	assert_output --partial "import scala.concurrent.Future"
}
