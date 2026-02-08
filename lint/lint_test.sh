#!/usr/bin/env bash
# Asserts that all lint executions succeed.

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

function assert_output_empty() {
  output_file=$(rlocation "$1")
  if [ -s "${output_file}" ]; then      
        cat ${output_file}
        exit 1
  fi
}

function assert_exit_code() {
  exit_code=$(cat $(rlocation "$1"))
  output_file=$(rlocation "$2")
  if [[ "$exit_code" != "{{expected_exit_code}}" ]]; then
    cat $output_file
    exit 1
  fi
}

# Dynamically populated by lint_test.bzl
{{asserts}}
