#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
RELEASES=$(mktemp)
RAW=$(mktemp)

REPOSITORY=${1:-"astral-sh/ruff"}

JQ_FILTER=\
'map(
  {
    "key": .tag_name,
    "value": .assets
        | map(select((.name | contains("ruff-")) and (.name | contains("sha256") | not) ))
        | map({
            "key": .name | ltrimstr("ruff-") | rtrimstr(".tar.gz") | rtrimstr(".zip"),
            "value": (.browser_download_url + ".sha256"),
        })
        | from_entries
  }
) | from_entries'

SHA256_FILTER=\
'
map(
    select(.name == $tag)
    | .assets
    | map(.browser_download_url)[]
    | select(endswith(".sha256"))
)[]
'


curl > $RELEASES \
  --silent \
  --header "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/${REPOSITORY}/releases?per_page=2  

jq "$JQ_FILTER" <$RELEASES >$RAW

FIXED=$(mktemp)
# Replace URLs with their hash
for tag in $(jq -r 'keys | .[]' < $RAW); do
  # Download checksums for this tag
  for sha256url in $(jq --arg tag $tag -r "$SHA256_FILTER" < $RELEASES); do
    sha256=$(curl --silent --location $sha256url | awk '{print $1}')
    jq ".[\"$tag\"] |= with_entries(.value = (if .value == \"$sha256url\" then \"$sha256\" else .value end))" < $RAW > $FIXED
    mv $FIXED $RAW
  done
done

echo -n "RUFF_VERSIONS = "
cat $RAW
