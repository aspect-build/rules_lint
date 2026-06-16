#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Argument provided by reusable workflow caller, see
# https://github.com/bazel-contrib/.github/blob/d197a6427c5435ac22e56e33340dff912bc9334e/.github/workflows/release_ruleset.yaml#L72
TAG=$1
# The prefix is chosen to match what GitHub generates for source archives
PREFIX="rules_lint-${TAG:1}"
ARCHIVE="rules_lint-$TAG.tar.gz"
ARCHIVE_TMP=$(mktemp)

# NB: configuration for 'git archive' is in /.gitattributes
git archive --format=tar --prefix=${PREFIX}/ ${TAG} >$ARCHIVE_TMP

# Add generated API docs to the release, see https://github.com/bazelbuild/bazel-central-registry/issues/5593
docs="$(mktemp -d)"; targets="$(mktemp)"
bazel --output_base="$docs" query --output=label --output_file="$targets" 'kind("starlark_doc_extract rule", //lint/... union //format/...)'
bazel --output_base="$docs" build --target_pattern_file="$targets"
tar --create --auto-compress \
    --directory "$(bazel --output_base="$docs" info bazel-bin)" \
    --file "$GITHUB_WORKSPACE/${ARCHIVE%.tar.gz}.docs.tar.gz" .

############
# Patch up the archive to have integrity hashes for built binaries that we downloaded in the GHA workflow.
# Now that we've run `git archive` we are free to pollute the working directory.

# Delete the placeholder file
tar --file $ARCHIVE_TMP --delete ${PREFIX}/tools/integrity.bzl

mkdir -p ${PREFIX}/tools
cat >${PREFIX}/tools/integrity.bzl <<EOF
"Generated during release by release_prep.sh"

RELEASED_BINARY_INTEGRITY = $(
  jq \
    --from-file .github/workflows/integrity.jq \
    --slurp \
    --raw-input go-binaries/*.sha256
)
EOF

# Fail the release if any sarif_parser platform the toolchain requires is missing
# an integrity entry. Without this, a dropped or unbuilt release binary silently
# produces an incomplete RELEASED_BINARY_INTEGRITY, and the gap only surfaces at
# `bazel build` time in a consuming repo as
# "key \"sarif_parser-<platform>\" not found in dictionary" (see #906).
# The required platforms are the keys of SARIF_PARSER_PLATFORMS.
missing=()
for platform in $(grep -oE '^    "[a-z0-9_]+": struct\(' tools/toolchains/sarif_parser_toolchain.bzl | sed -E 's/^    "([^"]+)".*/\1/'); do
  ext=""
  [[ "$platform" == windows_* ]] && ext=".exe"
  key="sarif_parser-${platform}${ext}"
  if ! grep -q "\"${key}\"" ${PREFIX}/tools/integrity.bzl; then
    missing+=("$key")
  fi
done
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "ERROR: release integrity is missing entries for: ${missing[*]}" >&2
  echo "The go-binaries/ artifact did not contain a .sha256 for every required" >&2
  echo "sarif_parser platform. Aborting to avoid publishing a broken release." >&2
  echo "Generated tools/integrity.bzl was:" >&2
  cat ${PREFIX}/tools/integrity.bzl >&2
  exit 1
fi

# Append that generated file back into the archive
tar --file $ARCHIVE_TMP --append ${PREFIX}/tools/integrity.bzl

# END patch up the archive
############

gzip <$ARCHIVE_TMP >$ARCHIVE
# Note: this happens to match what we publish to BCR in source.json, though it's not required to
INTEGRITY="sha256-$(shasum -a 256 $ARCHIVE | xxd -p -r | base64)"

cat << EOF
Add this to your `MODULE.bazel` file:

\`\`\`starlark
bazel_dep(name = "aspect_rules_lint", version = "${TAG:1}")
\`\`\`

This repo also provides a \`lint\` task for the [Aspect CLI].
Add this to your \`MODULE.aspect\` file:

\`\`\`starlark
# AXL dependencies; see https://github.com/aspect-extensions
axl_archive_dep(
    name = "aspect_rules_lint",
    urls = ["https://github.com/aspect-build/rules_lint/releases/download/${TAG}/rules_lint-${TAG}.tar.gz"],
    integrity = "${INTEGRITY}",
    strip_prefix = "rules_lint-${TAG:1}",
    dev = True,
    auto_use_tasks = True,
)
\`\`\`

Then, follow the install instructions for
- linting: https://github.com/aspect-build/rules_lint/blob/${TAG}/docs/linting.md
- formatting: https://github.com/aspect-build/rules_lint/blob/${TAG}/docs/formatting.md

[Aspect CLI]: https://docs.aspect.build/cli
EOF
