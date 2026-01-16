#!/usr/bin/env bash
# The wrapper is only required to resolve symlinks before calling the tool.
# https://github.com/semgrep/semgrep/issues/11406

set +e

# The first argument is the binary.
semgrep="$1"
shift

args=("$@")

# find position of --
for i in "${!args[@]}"; do [[ ${args[i]} == -- ]] && break; done
# semgrep doesn't handle symlinks, https://github.com/semgrep/semgrep/issues/11406
mapfile -t files < <(readlink -f -- "${args[@]:i+1}")
set -- "${args[@]:0:i+1}" "${files[@]}"

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

eval "$semgrep" ${@} 2>/dev/null > "$out_file"
exit_code="$?"
test -n "$exit_code_path" && echo "$exit_code" > "$exit_code_path" || exit $exit_code
