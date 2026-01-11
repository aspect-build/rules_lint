#!/usr/bin/env bash
# The wrapper is only required to resolve symlinks before calling the tool.
# https://github.com/semgrep/semgrep/issues/11406

set +e

# The first argument is the binary, the last is the file to scan.
semgrep="$1"
file="${@: -1}"
set -- "${@:2:$#-2}"

if [ -n "$RULES_LINT__SEMGREP__STDOUT_FILE" ]; then
    out_file="$RULES_LINT__SEMGREP__STDOUT_FILE"
else
    out_file=$(mktemp)
fi
if [ -n "$RULES_LINT__SEMGREP__EXIT_CODE_FILE" ]; then
    exit_code_path="$RULES_LINT__SEMGREP__EXIT_CODE_FILE"
    touch "$exit_code_path"
fi

# must exist
touch "$out_file"

eval "$semgrep" ${@} "$(readlink "$file")" > "$out_file"
exit_code="$?"
test -n "$exit_code_path" && echo "$exit_code" > "$exit_code_path" || exit $exit_code
