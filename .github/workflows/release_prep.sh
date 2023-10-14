#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Set by GH actions, see
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
TAG=${GITHUB_REF_NAME}
# The prefix is chosen to match what GitHub generates for source archives
PREFIX="rules_eslint-${TAG:1}"
ARCHIVE="rules_eslint-$TAG.tar.gz"
git archive --format=tar --prefix=${PREFIX}/ ${TAG} | gzip > $ARCHIVE
SHA=$(shasum -a 256 $ARCHIVE | awk '{print $1}')

cat << EOF
## Using Bzlmod with Bazel 6

1. Enable with \`common --enable_bzlmod\` in \`.bazelrc\`.
2. Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "aspect_rules_eslint", version = "${TAG:1}")

# Next, follow the install instructions for
# - linting: https://github.com/aspect-build/rules_lint/blob/${TAG}/docs/linting.md
# - formatting: https://github.com/aspect-build/rules_lint/blob/${TAG}/docs/formatting.md
\`\`\`
EOF

