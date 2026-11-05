bats_load_library "bats-support"
bats_load_library "bats-assert"

# Generated C++ files inside this workspace, so .clang-format and git attributes
# apply. Every third one needs formatting.
setup() {
	root=$(mktemp -d "$PWD/test/format-parallel.XXXXXX")
	mkdir -p "$root/base/plain" "$root/base/with space"
	for ((i = 1; i <= 300; i++)); do
		sub="$root/base/plain"
		((i % 2)) || sub="$root/base/with space"
		if ((i % 3 == 0)); then
			printf 'int f%d(int a,int b){return a+b;}\n' "$i" >"$sub/$(printf 'f%04d' "$i").cc"
		else
			printf 'int f%d(int a, int b) { return a + b; }\n' "$i" >"$sub/$(printf 'f%04d' "$i").cc"
		fi
	done
	expected=$(for ((i = 3; i <= 300; i += 3)); do printf 'f%04d.cc\n' "$i"; done)
}

teardown() {
	rm -rf "$root"
}

# reported: the generated files named in $output, sorted.
function reported() {
	grep -oE 'f[0-9]{4}\.cc' <<<"$output" | LC_ALL=C sort -u || true
}

@test "clang-format reports and fixes the same files serially and in parallel batches" {
	cp -R "$root/base" "$root/serial"
	cp -R "$root/base" "$root/parallel"

	RULES_LINT_FORMAT_CPUS=1 run bazel run //tools/format:format.check -- "$root/serial"
	assert_failure
	assert_equal "$(reported)" "$expected"
	RULES_LINT_FORMAT_CPUS=4 run bazel run //tools/format:format.check -- "$root/parallel"
	assert_failure
	assert_equal "$(reported)" "$expected"

	RULES_LINT_FORMAT_CPUS=1 run bazel run //tools/format -- "$root/serial"
	assert_success
	RULES_LINT_FORMAT_CPUS=4 run bazel run //tools/format -- "$root/parallel"
	assert_success
	run diff -r "$root/base" "$root/serial"
	assert_failure
	run diff -r "$root/serial" "$root/parallel"
	assert_success

	RULES_LINT_FORMAT_CPUS=4 run bazel run //tools/format:format.check -- "$root/parallel"
	assert_success

	# parallel in tools/format/BUILD lists cc, so the runs above used batches.
	run grep -c "export parallel='true'" "$(bazel info bazel-bin)/tools/format/format_C++_with_clang-format.bash"
	assert_output 1
}
