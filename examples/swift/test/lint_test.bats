bats_load_library "bats-support"
bats_load_library "bats-assert"

function assert_swift_lints() {
	assert_output --partial '"ruleId" : "function_name_whitespace"'
	assert_output --partial '"uri" : "src/lintme.swift"'
	assert_output --partial '"text" : "Too many spaces between '\''func'\'' and function name"'
}

function assert_swift_fix_patch() {
	assert_output --partial - <<'EOF'
--- a/src/lintme.swift
+++ b/src/lintme.swift
@@ -1,5 +1,5 @@
 class Controller {
-    func  printme() {
+    func printme() {
         print("Hello, World!")
     }
 }
EOF
}

function assert_swift_nested_fix_patch() {
	assert_output --partial - <<'EOF'
--- a/src/nested_fix/lintme.swift
+++ b/src/nested_fix/lintme.swift
@@ -1,5 +1,5 @@
 class NestedFixController {
-    func  printme() {
+    func printme() {
         print("Hello, World!")
     }
 }
EOF
}

@test "should produce reports" {
	run aspect lint //src:all
	assert_failure
	assert_swift_lints
}

@test "should produce fix patches" {
	run bazel build --config=lint --output_groups=rules_lint_patch --@aspect_rules_lint//lint:fix //src:lint
	assert_success

	run cat bazel-bin/src/lint.AspectRulesLintSwiftLint.patch
	assert_success
	assert_swift_fix_patch
}

@test "should produce nested config fix patches" {
	run bazel build --aspects=//tools/lint:linters.bzl%swiftlint_nested_fix_config --output_groups=rules_lint_patch --@aspect_rules_lint//lint:fix //src:nested_fix_config
	assert_success

	run cat bazel-bin/src/nested_fix_config.AspectRulesLintSwiftLint.patch
	assert_success
	assert_swift_nested_fix_patch
}
