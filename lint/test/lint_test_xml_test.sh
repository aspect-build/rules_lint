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

# Tests that lint_test writes JUnit XML with one testcase per linted target and
# the linter report in the <failure> body, rather than leaving Bazel to generate
# XML that only says the test exited non-zero.

set -o nounset -o errexit -o pipefail

lint_test="$(rlocation "$1")"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
xml="$tmp_dir/test.xml"

status=0
XML_OUTPUT_FILE="$xml" TEST_TARGET="//lint/test:fake_lint" "$lint_test" > "$tmp_dir/stdout" || status=$?

function fail() {
    echo "FAIL: $1" >&2
    echo "--- test.xml:" >&2
    cat "$xml" >&2 || true
    exit 1
}

function assert_xml_contains() {
    grep -qF -- "$1" "$xml" || fail "test.xml does not contain: $1"
}

[[ $status -eq 1 ]] || fail "expected lint_test to exit 1, got $status"
grep -qF "error <&>" "$tmp_dir/stdout" || fail "the report was not printed to the test log"

assert_xml_contains '<testsuite name="//lint/test:fake_lint" tests="2" failures="1" errors="0">'
assert_xml_contains '<testcase name="//lint/test:clean_target" classname="//lint/test:fake_lint"/>'
assert_xml_contains '<testcase name="//lint/test:dirty_target" classname="//lint/test:fake_lint"><failure message="linter exited with code 1, expected 0">'
assert_xml_contains '<![CDATA[file.py:1:1: error <&> "quoted" ]]]]><![CDATA[> end'

if grep -q "$(printf '\033')" "$xml"; then
    fail "test.xml contains ANSI escape codes, which are not valid XML"
fi

echo "PASS"
