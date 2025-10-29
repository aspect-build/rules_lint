#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

(cd "${SCRIPT_DIR}" && bazel run @paket.main//paket/tools:paket -- install)
bazel run @rules_dotnet//tools/paket2bazel -- --dependencies-file "${SCRIPT_DIR}/paket.dependencies" --output-folder "${SCRIPT_DIR}/3rdparty/nuget"
