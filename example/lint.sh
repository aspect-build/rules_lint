#!/usr/bin/env bash
#
# Shows an end-to-end workflow for linting without failing the build.
# This is meant to mimic the behavior of the `bazel lint` command that you'd have
# by using the Aspect CLI with the plugin in this repository.
#
# We recommend using Aspect CLI instead!
set -o errexit -o pipefail -o nounset

if [ "$#" -eq 0 ]; then
    echo "usage: lint.sh [target pattern...]"
    exit 1
fi

# Produce report files
# You can add --aspects_parameters=fail_on_violation=true to make this command fail instead.
bazel build --aspects //:lint.bzl%eslint,//:lint.bzl%buf,//:lint.bzl%flake8 --output_groups=report $@

# Show the results.
# `-mtime -1`: only look at files modified in the last day, to mitigate showing stale results of old bazel runs.
# `-size +1c`: don't show files containing zero bytes
for report in $(find $(bazel info bazel-bin) -mtime -1 -size +1c -type f -name "*-report.txt"); do
    echo "From ${report}:"
    cat "${report}"
    echo
done
