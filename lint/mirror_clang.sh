#!/usr/bin/env bash
set -x
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
RELEASES=$(mktemp)
RAW=$(mktemp)

REPOSITORY=${1:-"llvm/llvm-project"}
JQ_FILTER=\
'map(
  {
    "key": .tag_name,
    "value": .assets
        | map(select((.name | contains("vale_")) and (.name | endswith("checksums.txt") | not) ))
        | map({
            "key": .name | capture("clang+llvm-[0-9\\.]+-(?<platform>.*)\\.(tar\\.gz|tar\\.xz)") | .platform,
            "value": .name,
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
    | select(endswith("checksums.txt"))
)[]
'

curl > $RELEASES \
  --silent \
  --header "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/${REPOSITORY}/releases?per_page=1

jq "$JQ_FILTER" <$RELEASES >$RAW

# Combine the new versions with the existing ones.
# New versions should appear first, but existing content should overwrite new
CURRENT=$(mktemp)
python -c 'import json; exec(open("$SCRIPT_DIR/clang_versions.bzl").read()); print(json.dumps(CLANG_VERSIONS))' > $CURRENT
OUT=$(mktemp)
jq --slurp '.[0] * .[1]' $RAW $CURRENT > $OUT

# Overwrite the file with updated content
(
  echo '"This file is automatically updated by mirror_clang.sh"'
  echo -n "CLANG_VERSIONS = "
  cat $OUT
)>$SCRIPT_DIR/clang_versions.bzl

echo "For now, you must manually replace placeholder sha256 with their content from checksums.txt:"
echo "https://github.com/llvm/llvm-project/releases/download/18.1.7/llvm_checksums.txt"
