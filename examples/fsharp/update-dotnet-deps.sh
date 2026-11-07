#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# paket resolves paket.dependencies relative to its working directory, so run it in this folder
# rather than in the runfiles tree that `bazel run` would otherwise use.
(cd "${SCRIPT_DIR}" && bazel run --run_under="cd ${SCRIPT_DIR} &&" @paket.main//paket/tools:paket -- install)
bazel run @rules_dotnet//tools/paket2bazel -- --dependencies-file "${SCRIPT_DIR}/paket.dependencies" --output-folder "${SCRIPT_DIR}/3rdparty/nuget"
