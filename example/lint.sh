#!/usr/bin/env bash
# Shows an end-to-end workflow for linting without failing the build
set -o errexit -o pipefail -o nounset

# Produce report files
bazel build //... --aspects //:lint.bzl%eslint,//:lint.bzl%buf -s --output_groups=report

# Process them
find $(bazel info bazel-bin) -type f -name "*-report.txt" | xargs cat
