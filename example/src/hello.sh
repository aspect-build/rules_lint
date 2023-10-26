#!/bin/bash

[ -z $THING ] && echo "hello world"

# Note, we should not get a lint here because the .shellcheckrc excludes it
[ ! -z "$foo" ] && echo "foo"
