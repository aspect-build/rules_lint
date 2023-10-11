#!/usr/bin/env bash
# Shows an end-to-end workflow for linting without failing the build
set -o errexit -o pipefail -o nounset

if [ "$#" -eq 0 ]; then
    echo "usage: lint.sh [target pattern...]"
    exit 1
fi

# Produce report files
bazel build --aspects //:lint.bzl%eslint,//:lint.bzl%buf --output_groups=report $@

# Process them
find $(bazel info bazel-bin) -type f -name "*-report.txt" | xargs cat
