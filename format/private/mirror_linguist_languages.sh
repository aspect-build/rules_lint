#!/usr/bin/env bash
# Generate a snippet of bash code to help us detect languages based on filenames
raw=$(mktemp --suffix=.yml)
json=$(mktemp --suffix=.json)
wget -O "$raw" https://raw.githubusercontent.com/github-linguist/linguist/master/lib/linguist/languages.yml
# We could do this entirely in yq, but the author happens to already know JQ :shrug:
yq -o=json '.' "$raw" | jq --from-file=filter.jq --raw-output
