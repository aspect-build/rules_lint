#!/usr/bin/env bash
# Tests format.sh's CPU budget and parallel batches with a mock formatter.

set -o nounset -o errexit -o pipefail

FORMAT_SH="$TEST_SRCDIR/_main/format/private/format.sh"
BUILD_WORKSPACE_DIRECTORY=$TEST_TMPDIR source "$FORMAT_SH"

function fail {
    echo >&2 "FAIL: $*"
    exit 1
}

# A mock formatter: one "call" line per process, then each file argument on its
# own line. Exits 1 when given the file named in $MOCK_FAIL_ON. With $MOCK_LOCK,
# records "overlap" in $MOCK_LOCK.overlap when two calls run at once. With
# $MOCK_PIDS, writes its pid there and becomes a long sleep, like a slow
# formatter binary.
cat >mock_formatter.sh <<'EOF'
#!/usr/bin/env bash
if [[ -n "${MOCK_PIDS:-}" ]]; then
    echo $$ >"$MOCK_PIDS/$$"
    exec sleep 30
fi
if [[ -n "${MOCK_LOCK:-}" ]]; then
    mkdir "$MOCK_LOCK" 2>/dev/null || echo overlap >>"$MOCK_LOCK.overlap"
    sleep 0.05
fi
echo call
for f in "$@"; do
    echo "$f"
    [[ "$f" != "${MOCK_FAIL_ON:-}" ]] || { echo >&2 "error in $f"; exit 1; }
done
if [[ -n "${MOCK_LOCK:-}" ]]; then
    rmdir "$MOCK_LOCK"
fi
EOF
chmod +x mock_formatter.sh
mock="$PWD/mock_formatter.sh"

# numbered <prefix> <count>: <prefix>0001.txt to <prefix><count>.txt, one per line.
# BusyBox seq has no -f.
function numbered {
    local i
    for ((i = 1; i <= $2; i++)); do
        printf '%s%04d.txt\n' "$1" "$i"
    done
}

# Batches only take paths that exist, so the tests create their files.
mkdir -p src
files=$(numbered src/file 1000)
small=$(numbered src/file 100)
for f in $files; do : >"$f"; done

function calls {
    grep -c '^call' <<<"$1" || true
}

# assert_files <name> <output> <expected files>: the output lists every file once, in order.
function assert_files {
    [[ "$(grep -v '^call' <<<"$2")" == "$3" ]] || fail "$1: output lost, duplicated or reordered files"
}

# assert_serial <name> <output>: one formatter process.
function assert_serial {
    [[ "$(calls "$2")" == 1 ]] || fail "$1 should run one process, ran $(calls "$2")"
}

# cpu-budget: RULES_LINT_FORMAT_CPUS when it is a positive number or auto,
# otherwise auto, which is at most 16.
auto=$(cpu-budget)
((auto >= 1 && auto <= 16)) || fail "auto budget out of range: $auto"
[[ "$(RULES_LINT_FORMAT_CPUS=3 cpu-budget)" == 3 ]] || fail "the override should apply"
[[ "$(RULES_LINT_FORMAT_CPUS=auto cpu-budget)" == "$auto" ]] || fail "the override should accept auto"
[[ "$(RULES_LINT_FORMAT_CPUS=junk cpu-budget)" == "$auto" ]] || fail "an invalid override should be ignored"
[[ "$(RULES_LINT_FORMAT_CPUS=0 cpu-budget)" == "$auto" ]] || fail "a zero override should be ignored"

# Parallel batches: every file once, in input order.
out=$(parallel=true RULES_LINT_FORMAT_CPUS=8 format-files "$files" "$mock")
(($(calls "$out") > 1)) || fail "expected several batches with RULES_LINT_FORMAT_CPUS=8, got $(calls "$out")"
assert_files "parallel batches" "$out" "$files"

# The batching threshold is 128 files.
for n in 127 128 129; do
    list=$(numbered src/file "$n")
    out=$(parallel=true RULES_LINT_FORMAT_CPUS=8 format-files "$list" "$mock")
    assert_files "$n files" "$out" "$list"
    if ((n < 128)); then
        [[ "$(calls "$out")" == 1 ]] || fail "$n files should run one process"
    else
        (($(calls "$out") > 1)) || fail "$n files should run as batches"
    fi
done

# Paths with spaces and shell metacharacters reach the formatter unchanged.
odd=$(printf '%s\n' "src/a b.txt" "src/it's.txt" 'src/$HOME*.txt' "src/[x].txt" "src/semi;colon.txt" 'src/back\slash.txt' "src/-dash.txt")
list=$(printf '%s\n%s' "$odd" "$(numbered src/pad 200)")
while IFS= read -r f; do : >"$f"; done <<<"$list"
assert_files "unusual paths in batches" "$(parallel=true RULES_LINT_FORMAT_CPUS=4 format-files "$list" "$mock")" "$list"
assert_files "unusual paths serially" "$(format-files "$list" "$mock")" "$list"

# A batch longer than xargs's command line splits into several calls, in order.
# Each path is 20,000 characters, too long to create, so this calls run-batches
# directly.
pad=$(printf '%*s' 20000 '' | tr ' ' x)
long=$(for i in $(seq 1 200); do printf "src/%05d%s.txt\n" "$i" "$pad"; done)
out=$(run-batches "$long" 2 64 "$mock")
(($(calls "$out") > 4)) || fail "long paths should split batches into more calls than batches, got $(calls "$out")"
assert_files "long paths in batches" "$out" "$long"

# Serial means no two formatter calls at once, even when xargs splits the list.
lock="$TEST_TMPDIR/serial.lock"
out=$(MOCK_LOCK="$lock" format-files "$long" "$mock")
(($(calls "$out") > 1)) || fail "the serial long-path run should take several calls"
[[ ! -e "$lock.overlap" ]] || fail "serial calls overlapped"
assert_files "long paths serially" "$out" "$long"

# Batches run only when every path names a different file. A repeated path, or
# a different path to a listed file, runs the set serially with every path: ./,
# a symlinked directory, .., //, an absolute path, a symlink to a file and a
# hard link.
mkdir -p alias/src
(cd alias && for f in $(numbered src/f 200); do : >"$f"; done)
ln -s src alias/link
ln -s f0001.txt alias/src/symlink.txt
ln alias/src/f0002.txt alias/src/hard.txt
first=$(numbered src/f 200)
for extra in src/f0003.txt ./src/f0003.txt link/f0003.txt src/../src/f0003.txt src//f0003.txt \
    "$PWD/alias/src/f0003.txt" src/symlink.txt src/hard.txt; do
    list=$(printf '%s\n%s' "$first" "$extra")
    out=$(cd alias && parallel=true RULES_LINT_FORMAT_CPUS=2 format-files "$list" "$mock")
    assert_serial "$extra after its file" "$out"
    assert_files "$extra after its file" "$out" "$list"
done
# The same through find, given overlapping directories.
for f in $(numbered alias/src/f 200); do mv "$f" "${f%.txt}.py"; done
out=$(cd alias && disable_git_attribute_checks=true && found=$(ls-files Python src ./src link/) &&
    parallel=true RULES_LINT_FORMAT_CPUS=2 format-files "$found" "$mock")
assert_serial "overlapping directory arguments" "$out"
# Without overlap, the same files run as batches.
out=$(cd alias && disable_git_attribute_checks=true && found=$(ls-files Python src) &&
    parallel=true RULES_LINT_FORMAT_CPUS=2 format-files "$found" "$mock")
(($(calls "$out") > 1)) || fail "distinct files found by find should run as batches"

# A missing file, a stat that fails, or one that reports inode 0 also runs the
# set serially with every path.
assert_serial "a missing file" "$(parallel=true RULES_LINT_FORMAT_CPUS=8 format-files "$files"$'\nsrc/missing.txt' "$mock")"
mkdir -p stubs/fail stubs/zero
printf '#!/bin/sh\nexit 1\n' >stubs/fail/stat
printf '#!/bin/sh\nfor f; do echo 0; done\n' >stubs/zero/stat
chmod +x stubs/fail/stat stubs/zero/stat
for stub in fail zero; do
    out=$(PATH="$PWD/stubs/$stub:$PATH" parallel=true RULES_LINT_FORMAT_CPUS=8 format-files "$files" "$mock")
    assert_serial "stat that reports $stub" "$out"
    assert_files "stat that reports $stub" "$out" "$files"
done

# A language that is not listed in parallel, a small set, or a budget of 1 runs
# one process. format_test never sets parallel.
assert_serial "a formatter not marked parallel" "$(RULES_LINT_FORMAT_CPUS=8 format-files "$files" "$mock")"
assert_serial "parallel=false" "$(parallel=false RULES_LINT_FORMAT_CPUS=8 format-files "$files" "$mock")"
assert_serial "RULES_LINT_FORMAT_CPUS=1" "$(parallel=true RULES_LINT_FORMAT_CPUS=1 format-files "$files" "$mock")"
assert_serial "a small set" "$(parallel=true RULES_LINT_FORMAT_CPUS=8 format-files "$small" "$mock")"
# Without the override a listed language uses the auto budget.
if ((auto >= 2)); then
    (($(calls "$(parallel=true format-files "$files" "$mock")") > 1)) || fail "a listed language should run as batches with the auto budget"
fi

# A failing batch fails the run, and the other batches' output is still printed.
code=0
out=$(MOCK_FAIL_ON=src/file0500.txt parallel=true RULES_LINT_FORMAT_CPUS=8 format-files "$files" "$mock" 2>err.txt) || code=$?
((code != 0)) || fail "a failing batch should fail format-files"
grep -q 'error in src/file0500.txt' err.txt || fail "the failing batch's stderr should be printed"
grep -q '^src/file1000.txt$' <<<"$out" || fail "batches after the failure should still be printed"

# An interrupt stops every formatter, and on_exit removes the batch files:
# TERM sent to the script alone, and INT sent to its process group, as a
# terminal's Ctrl-C does. Job control gives the background shell its own group,
# so the signal does not reach this test.
for how in TERM:pid INT:group; do
    signal="${how%%:*}"
    pids="$TEST_TMPDIR/pids.$signal"
    tmp="$TEST_TMPDIR/tmp.$signal"
    mkdir -p "$pids" "$tmp"
    set -m
    TMPDIR="$tmp" MOCK_PIDS="$pids" BUILD_WORKSPACE_DIRECTORY="$TEST_TMPDIR" parallel=true RULES_LINT_FORMAT_CPUS=4 \
        bash -c 'source "$1"; format-files "$2" "$3"' _ "$FORMAT_SH" "$files" "$mock" >/dev/null 2>"$TEST_TMPDIR/child.$signal.err" &
    shell=$!
    set +m
    for _ in $(seq 1 100); do
        (($(ls "$pids" | wc -l) >= 4)) && break
        sleep 0.1
    done
    (($(ls "$pids" | wc -l) >= 4)) || fail "$signal: the formatters did not start"
    start=$SECONDS
    if [[ "$how" == *:group ]]; then
        kill -"$signal" -"$shell"
    else
        kill -"$signal" "$shell"
    fi
    code=0
    wait "$shell" || code=$?
    # The mock formatters sleep 30s, so finishing them would take longer.
    ((SECONDS - start < 10)) || fail "$signal: the script took $((SECONDS - start))s to stop"
    ((code != 0)) || fail "$signal: the script should fail when interrupted"
    # A killed formatter whose parent died too lingers until launchd or init reaps it.
    for pid in $(cat "$pids"/*); do
        for _ in $(seq 1 20); do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.1
        done
        ! kill -0 "$pid" 2>/dev/null || fail "$signal: formatter $pid is still running: $(ps -o pid,ppid,pgid,stat,command -p "$pid" | tail -1)"
    done
    [[ -z "$(ls -A "$tmp")" ]] || fail "$signal: batch files were left in TMPDIR: $(ls -A "$tmp")"
done

echo "PASS"
