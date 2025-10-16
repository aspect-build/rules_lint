#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
CPPCHECK_BINARY="$SCRIPT_DIR/cppcheck.runfiles/@@CPPCHECK_BINARY@@"

"$CPPCHECK_BINARY" \
    --check-level=exhaustive \
    --enable=warning,style,performance,portability,information \
    "$@"
