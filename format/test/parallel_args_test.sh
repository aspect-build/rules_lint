#!/usr/bin/env bash
# What format_multirun's parallel argument sets in the generated commands.

set -o nounset -o errexit -o pipefail

dir="$TEST_SRCDIR/_main/format/test"

function fail {
    echo >&2 "FAIL: $*"
    exit 1
}

grep -q "export parallel='false'" "$dir/format_Python_with_ruff.bash" || fail "batches should be off by default"
grep -q "export parallel='true'" "$dir/format_parallel_Python_with_ruff.bash" || fail "parallel = [\"python\"] should allow batches"
grep -q "export parallel='false'" "$dir/format_parallel_Shell_with_shfmt.bash" || fail "a language not in parallel should stay serial"

echo "PASS"
