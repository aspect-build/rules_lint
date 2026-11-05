#!/bin/sh
# Rewrites its file only when PATH is in its environment, as a linter that is a
# shell script needs it to find coreutils.
case "$(/usr/bin/env)" in
PATH=* | *"
PATH="*) echo fixed >"$1" ;;
esac
