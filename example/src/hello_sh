#!/bin/bash

# Missing quotes, auto-fixable under `--fix`
[ -z $THING ] && echo "hello world"

# Note, we should not get a lint here because the .shellcheckrc excludes it
[ ! -z "$foo" ] && echo "foo"

# Not auto-fixable. Should be reported under `--fix` and lint exits 1
grep '*foo*' file
