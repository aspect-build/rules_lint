#!/usr/bin/env bash
# TODO:
# - should this program be written in a different language?
# - if bash, we could reuse https://github.com/github/super-linter/blob/main/lib/functions/worker.sh
# - can we detect what version control system is used? (start with git)

if [[ -z "$BUILD_WORKSPACE_DIRECTORY" ]]; then
  echo >&2 "$0: FATAL: This program must be executed under 'bazel run'"
  exit 1
fi

function on_exit {
  code=$?
  if [[ $code != 0 ]]; then
    echo >&2 "FAILED: A formatter tool exited with code $code"
    echo >&2 "Try running 'bazel run {{fix_target}}' to fix this."
  fi
}

trap on_exit EXIT

mode=fix
if [ "$1" == "--mode" ]; then
  readonly mode=$2
  shift 2
fi

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
# https://github.com/bazelbuild/bazel/blob/master/tools/bash/runfiles/runfiles.bash
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

cd $BUILD_WORKSPACE_DIRECTORY

# NOTE: we need to honor .gitignore, so we use git ls-files below
# TODO: talk to version control to determine which staged changes we should format
# TODO: avoid formatting unstaged changes
# TODO: try to format only regions where supported
# TODO: run them concurrently, not serial

case "$mode" in
 check)
   swiftmode="--lint"
   prettiermode="--check"
   ruffmode="format --check"
   shfmtmode="-l"
   javamode="--set-exit-if-changed --dry-run"
   ktmode="--set-exit-if-changed --dry-run"
   gofmtmode="-l"
   bufmode="format -d --exit-code"
   tfmode="-check -diff"
   jsonnetmode="--test"
   scalamode="--test"
   ;;
 fix)
   swiftmode=""
   prettiermode="--write"
   # Force exclusions in the configuration file to be honored even when file paths are supplied
   # as command-line arguments; see
   # https://github.com/astral-sh/ruff/discussions/5857#discussioncomment-6583943
   ruffmode="format --force-exclude"
   shfmtmode="-w"
   javamode="--replace"
   ktmode=""
   gofmtmode="-w"
   bufmode="format -w"
   tfmode=""
   jsonnetmode="--in-place"
   scalamode=""
   ;;
 *) echo >&2 "unknown mode $mode";;
esac

if [ "$#" -eq 0 ]; then
  files=$(git ls-files 'BUILD' '*/BUILD.bazel' '*.bzl' '*.BUILD' 'WORKSPACE' '*.bazel')
else
  files=$(find "$@" -name 'BUILD' -or -name '*.bzl' -or -name '*.BUILD' -or -name 'WORKSPACE' -or -name '*.bazel')
fi
bin=$(rlocation {{buildifier}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Running Buildifier..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin -mode="$mode"
fi

if [ "$#" -eq 0 ]; then
  files=$(git ls-files '*.js' '*.cjs' '*.mjs' '*.ts' '*.tsx' '*.mts' '*.cts' '*.json' '*.css' '*.html' '*.md')
else
  files=$(find "$@" -name '*.js' -or -name '*.cjs' -or -name '*.mjs' -or -name '*.ts' -or -name '*.tsx' -or -name '*.mts' -or -name '*.cts' -or -name '*.json' -or -name '*.css' -or -name '*.html' -or -name '*.md')
fi
bin=$(rlocation {{prettier}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Running Prettier..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $prettiermode
fi

if [ "$#" -eq 0 ]; then
  files=$(git ls-files '*.sql')
else
  files=$(find "$@" -name '*.sql')
fi
bin=$(rlocation {{prettier-sql}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Running Prettier (sql)..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $prettiermode
fi

if [ "$#" -eq 0 ]; then
  files=$(git ls-files '*.py' '*.pyi')
else
  files=$(find "$@" -name '*.py' -or -name '*.pyi')
fi
bin=$(rlocation {{ruff}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Running ruff..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $ruffmode
fi

if [ "$#" -eq 0 ]; then
  files=$(git ls-files '*.tf')
else
  files=$(find "$@" -name '*.tf')
fi
bin=$(rlocation {{terraform}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Running terraform..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin fmt $tfmode
fi

if [ "$#" -eq 0 ]; then
  files=$(git ls-files '*.jsonnet' '*.libsonnet')
else
  files=$(find "$@" -name '*.jsonnet' -or -name '*.libsonnet')
fi
bin=$(rlocation {{jsonnetfmt}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Running jsonnetfmt..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $jsonnetmode
fi

if [ "$#" -eq 0 ]; then
  files=$(git ls-files '*.java')
else
  files=$(find "$@" -name '*.java')
fi
bin=$(rlocation {{java-format}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Running java-format..."
  # Setting JAVA_RUNFILES to work around https://github.com/bazelbuild/bazel/issues/12348
  echo "$files" | tr \\n \\0 | JAVA_RUNFILES="${RUNFILES_MANIFEST_FILE%_manifest}" xargs -0 $bin $javamode
fi

if [ "$#" -eq 0 ]; then
  files=$(git ls-files '*.kt')
else
  files=$(find "$@" -name '*.kt')
fi
bin=$(rlocation {{ktfmt}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Running ktfmt..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $ktmode
fi

if [ "$#" -eq 0 ]; then
  files=$(git ls-files '*.scala')
else
  files=$(find "$@" -name '*.scala')
fi
bin=$(rlocation {{scalafmt}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Running scalafmt..."
  # Setting JAVA_RUNFILES to work around https://github.com/bazelbuild/bazel/issues/12348
  echo "$files" | tr \\n \\0 | JAVA_RUNFILES="${RUNFILES_MANIFEST_FILE%_manifest}" xargs -0 $bin $scalamode
fi

if [ "$#" -eq 0 ]; then
  files=$(git ls-files '*.go')
else
  files=$(find "$@" -name '*.go')
fi
bin=$(rlocation {{gofmt}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Running gofmt..."
  # gofmt doesn't produce non-zero exit code so we must check for non-empty output
  # https://github.com/golang/go/issues/24230
  if [ "$mode" == "check" ]; then
    NEED_FMT=$(echo "$files" | tr \\n \\0 | xargs -0 $bin $gofmtmode)
    if [ -n "$NEED_FMT" ]; then
       echo "Go files not formatted:"
       echo "$NEED_FMT"
       exit 1
    fi
  else
    echo "$files" | tr \\n \\0 | xargs -0 $bin $gofmtmode
  fi
fi

if [ "$#" -eq 0 ]; then
  files=$(git ls-files '*.sh' '*.bash')
else
  files=$(find "$@" -name '*.sh' -or -name '*.bash')
fi
bin=$(rlocation {{shfmt}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Running shfmt..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $shfmtmode
fi

if [ "$#" -eq 0 ]; then
  files=$(git ls-files '*.swift')
else
  files=$(find "$@" -name '*.swift')
fi
bin=$(rlocation {{swiftformat}})

if [ -n "$files" ] && [ -n "$bin" ]; then
  # swiftformat itself prints Running SwiftFormat...
  echo "$files" | tr \\n \\0 | xargs -0 $bin $swiftmode
fi

if [ "$#" -eq 0 ]; then
  files=$(git ls-files '*.proto')
else
  files=$(find "$@" -name '*.proto')
fi
bin=$(rlocation {{buf}})

if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Running buf..."
  for file in $files; do
    $bin $bufmode $file
  done
fi
