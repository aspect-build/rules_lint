#!/usr/bin/env bash
# Asserts that all lint executions succeed.
#
# Each assert becomes a <testcase> in the JUnit XML at $XML_OUTPUT_FILE, with the
# linter report in the <failure> body, so CI systems can show the violations.
# Otherwise Bazel generates the XML, which only says the test exited non-zero.

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

testcases=""
tests=0
failures=0

function xml_attr() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  printf '%s' "$s"
}

# Linter output may be coloured, and XML 1.0 forbids most control characters,
# so strip ANSI escapes and those characters. "]]>" would end the CDATA early.
function xml_cdata() {
  local esc
  esc=$(printf '\033')
  printf '<![CDATA['
  sed -e "s/${esc}\[[0-9;]*[A-Za-z]//g" -e 's/]]>/]]]]><![CDATA[>/g' "$1" | tr -d '\000-\010\013\014\016-\037'
  printf ']]>'
}

function record_pass() {
  tests=$((tests + 1))
  testcases+="<testcase name=\"$(xml_attr "$1")\" classname=\"$(xml_attr "${TEST_TARGET:-lint}")\"/>"
}

function record_failure() {
  tests=$((tests + 1))
  failures=$((failures + 1))
  testcases+="<testcase name=\"$(xml_attr "$1")\" classname=\"$(xml_attr "${TEST_TARGET:-lint}")\">"
  testcases+="<failure message=\"$(xml_attr "$2")\">$(xml_cdata "$3")</failure></testcase>"
  cat "$3"
}

function assert_output_empty() {
  output_file=$(rlocation "$1")
  if [ -s "${output_file}" ]; then
    record_failure "$2" "lint violations found" "${output_file}"
  else
    record_pass "$2"
  fi
}

function assert_exit_code() {
  exit_code=$(cat "$(rlocation "$1")")
  output_file=$(rlocation "$2")
  if [[ "$exit_code" != "{{expected_exit_code}}" ]]; then
    record_failure "$3" "linter exited with code ${exit_code}, expected {{expected_exit_code}}" "${output_file}"
  else
    record_pass "$3"
  fi
}

# Dynamically populated by lint_test.bzl
{{asserts}}

if [[ -n "${XML_OUTPUT_FILE:-}" ]]; then
  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo "<testsuites><testsuite name=\"$(xml_attr "${TEST_TARGET:-lint}")\" tests=\"${tests}\" failures=\"${failures}\" errors=\"0\">"
    echo "${testcases}"
    echo '</testsuite></testsuites>'
  } > "${XML_OUTPUT_FILE}"
fi

if [[ ${failures} -ne 0 ]]; then
  exit 1
fi
