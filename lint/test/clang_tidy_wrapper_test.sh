#!/usr/bin/env bash
# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

# Tests for lint/clang_tidy_wrapper.bash.
#
# Regression test: the wrapper used to build a single string and `eval` it,
# which re-parsed arguments through the shell. Arguments containing shell
# metacharacters such as `-DDEPRECATED=__attribute__((deprecated))` then
# failed with "syntax error near unexpected token `('". The wrapper must
# invoke clang-tidy directly with "$@" so every argument arrives verbatim.

set -o nounset -o errexit -o pipefail

wrapper="$(rlocation "_main/lint/clang_tidy_wrapper.bash")"
if [[ ! -f "$wrapper" ]]; then
    echo "FAIL: clang_tidy_wrapper.bash not found in runfiles" >&2
    exit 1
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

# A recording mock for clang-tidy: writes each argument it receives on its
# own line, then exits with MOCK_EXIT_CODE (default 0).
mock_clang_tidy="$tmp_dir/mock-clang-tidy"
cat > "$mock_clang_tidy" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$MOCK_ARGS_FILE"
echo "mock clang-tidy output"
exit "${MOCK_EXIT_CODE:-0}"
EOF
chmod +x "$mock_clang_tidy"

failures=0

fail() {
    echo "FAIL: $1" >&2
    failures=$((failures + 1))
}

pass() {
    echo "PASS: $1"
}

#-------------------------------------------------------------------
# Test 1: arguments containing shell metacharacters are passed verbatim
# and are not re-parsed by the shell.

args=(
    "-DDEPRECATED_ATTR=__attribute__((deprecated))"
    "-DGREETING=\"hello world\""
    "-DCMD=\$(echo pwned)"
    "-DSEMI=a;b"
    "-DGLOB=*"
    "arg with spaces"
    "--"
    "-Ifoo/bar"
    "source file.cpp"
)

export MOCK_ARGS_FILE="$tmp_dir/args1.txt"
exit_code=0
MOCK_EXIT_CODE=0 "$wrapper" "$mock_clang_tidy" "${args[@]}" > "$tmp_dir/stdout1.txt" 2>&1 || exit_code=$?

if [[ $exit_code -ne 0 ]]; then
    fail "wrapper exited with $exit_code for metacharacter args (eval regression?):
$(cat "$tmp_dir/stdout1.txt")"
else
    pass "wrapper survives args with shell metacharacters"
fi

printf '%s\n' "${args[@]}" > "$tmp_dir/expected1.txt"
if diff -u "$tmp_dir/expected1.txt" "$MOCK_ARGS_FILE"; then
    pass "all arguments arrive at clang-tidy verbatim"
else
    fail "arguments were mangled before reaching clang-tidy"
fi

#-------------------------------------------------------------------
# Test 2: non-zero exit codes from clang-tidy are propagated.

export MOCK_ARGS_FILE="$tmp_dir/args2.txt"
exit_code=0
MOCK_EXIT_CODE=3 "$wrapper" "$mock_clang_tidy" "-DX=__attribute__((noreturn))" foo.cpp \
    > "$tmp_dir/stdout2.txt" 2>&1 || exit_code=$?

if [[ $exit_code -eq 3 ]]; then
    pass "clang-tidy exit code is propagated"
else
    fail "expected exit code 3, got $exit_code"
fi

#-------------------------------------------------------------------
# Test 3: with CLANG_TIDY__EXIT_CODE_OUTPUT_FILE set, the wrapper returns
# success and records the real exit code in the file.

export MOCK_ARGS_FILE="$tmp_dir/args3.txt"
export CLANG_TIDY__EXIT_CODE_OUTPUT_FILE="$tmp_dir/exit_code.txt"
export CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE="$tmp_dir/output.txt"
exit_code=0
MOCK_EXIT_CODE=2 "$wrapper" "$mock_clang_tidy" "-DY=__attribute__((unused))" bar.cpp \
    > "$tmp_dir/stdout3.txt" 2>&1 || exit_code=$?
unset CLANG_TIDY__EXIT_CODE_OUTPUT_FILE
unset CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE

if [[ $exit_code -eq 0 ]]; then
    pass "wrapper returns success when exit code file is requested"
else
    fail "expected exit code 0 with CLANG_TIDY__EXIT_CODE_OUTPUT_FILE, got $exit_code"
fi

if [[ "$(cat "$tmp_dir/exit_code.txt")" == "2" ]]; then
    pass "real exit code written to CLANG_TIDY__EXIT_CODE_OUTPUT_FILE"
else
    fail "expected '2' in exit code file, got '$(cat "$tmp_dir/exit_code.txt")'"
fi

if grep -q "mock clang-tidy output" "$tmp_dir/output.txt"; then
    pass "clang-tidy output captured in CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE"
else
    fail "clang-tidy output missing from CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE"
fi

#-------------------------------------------------------------------

if [[ $failures -ne 0 ]]; then
    echo "$failures test(s) failed" >&2
    exit 1
fi
echo "All clang_tidy_wrapper tests passed!"
