#!/usr/bin/env bash
# Wrapper around a formatter tool

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
# https://github.com/bazelbuild/bazel/blob/master/tools/bash/runfiles/runfiles.bash
set -o pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: runfiles.bash initializer cannot find $f. An executable rule may have forgotten to expose it in the runfiles, or the binary may require RUNFILES_DIR to be set."; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/ls-files.sh"

if [[ -n "$BUILD_WORKSPACE_DIRECTORY" ]]; then
  cd $BUILD_WORKSPACE_DIRECTORY
elif [[ -n "$TEST_WORKSPACE" ]]; then
  if [[ -n "$WORKSPACE" ]]; then
    WORKSPACE_PATH="$(dirname "$(realpath ${WORKSPACE})")"
    if ! cd "$WORKSPACE_PATH" ; then
      echo "Unable to change to workspace (WORKSPACE_PATH: ${WORKSPACE_PATH})"
      exit 1
    fi
  fi
else
  echo >&2 "$0: FATAL: WORKSPACE not set. This program should be executed under 'bazel run'."
  exit 1
fi

set -u

function on_exit {
  code=$?
  case "$code" in
    # return code 143 is the result of SIGTERM, which isn't failure, so suppress failure suggestion
    0|143)
      exit $code;
      ;;
    *)
      echo >&2 "FAILED: A formatter tool exited with code $code"
      echo >&2 "Try running 'bazel run $FIX_TARGET' to fix this."
      ;;
  esac
}

trap on_exit EXIT

function time-run {
  local files="$1" && shift
  local bin="$1" && shift
  local lang="$1" && shift
  local silent="$1" && shift
  local tuser
  local tsys

  ( if [ $silent != 0 ] ; then 2>/dev/null ; fi ; echo "$files" | tr \\n \\0 | xargs -0 "$bin" "$@" >&2 ; times ) | ( read _ _ ; read tuser tsys; echo "Formatted ${lang} in ${tuser}" )

}

function run-format {
  local lang="$1" && shift
  local bin="$1" && shift
  local args="$1" && shift
  local tuser
  local tsys

  local files=$(ls-files "$lang" $@)
  if [ -n "$files" ] && [ -n "$bin" ]; then
    case "$lang" in
    'Protocol Buffer')
        ( for file in $files; do
          "$bin" $args $file >&2
        done ; times ) | ( read _ _; read tuser tsys; echo "Formatted ${lang} in ${tuser}" )
        ;;
      Go)
        # gofmt doesn't produce non-zero exit code so we must check for non-empty output
        # https://github.com/golang/go/issues/24230
        if [ "$mode" == "check" ]; then
          GOFMT_OUT=$(mktemp)
          (echo "$files" | tr \\n \\0 | xargs -0 "$bin" $args > "$GOFMT_OUT" ; times ) | ( read _ _; read tuser tsys; echo "Formatted ${lang} in ${tuser}" )
          NEED_FMT="$(cat $GOFMT_OUT)"
          rm $GOFMT_OUT
          if [ -n "$NEED_FMT" ]; then
            echo "Go files not formatted:"
            echo "$NEED_FMT"
            exit 1
          fi
        else
          time-run "$files" "$bin" "$lang" 0 $args
        fi
        ;;
      Java|Scala)
          # Setting JAVA_RUNFILES to work around https://github.com/bazelbuild/bazel/issues/12348
          ( export JAVA_RUNFILES="${RUNFILES_DIR}" ; time-run "$files" "$bin" "$lang" 0 $args )
        ;;
      Swift)
        # for any formatter that must be silenced
        time-run "$files" "$bin" "$lang" 1 $args
        ;;
      *)
        time-run "$files" "$bin" "$lang" 0 $args
        ;;
    esac
  fi
}

bin="$(rlocation $tool)"
if [ ! -e "$bin" ]; then
  echo >&2 "cannot locate binary $tool"
  exit 1
fi

run-format "$lang" "$bin" "${flags:-""}" $@

# Currently these aren't exposed as separate languages to the attributes of format_multirun
# So we format all these languages as part of "JavaScript".
if [[ "$lang" == "JavaScript" ]]; then
  run-format "CSS" "$bin" "${flags:-""}" $@
  run-format "HTML" "$bin" "${flags:-""}" $@
  run-format "JSON" "$bin" "${flags:-""}" $@
  run-format "TSX" "$bin" "${flags:-""}" $@
  run-format "TypeScript" "$bin" "${flags:-""}" $@
fi
