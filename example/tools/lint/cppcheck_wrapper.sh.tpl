#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
CPPCHECK_BINARY="$SCRIPT_DIR/cppcheck.runfiles/@@CPPCHECK_BINARY@@"

# cppcheck does not support config files.
# Instead options like --check-level can be added here:
"$CPPCHECK_BINARY" \
    --check-level=exhaustive \
    --enable=warning,style,performance,portability,information \
    "$@"
