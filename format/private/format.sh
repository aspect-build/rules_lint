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

if [[ -n "$BUILD_WORKSPACE_DIRECTORY" ]]; then
  # Needed for the rustfmt binary wrapper in rules_rust; see
  # https://github.com/aspect-build/rules_lint/pull/327
  unset BUILD_WORKING_DIRECTORY
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

FIX_CMD="bazel run ${FIX_TARGET:-} $@"
function on_exit {
  code=$?
  case "$code" in
    # return code 143 is the result of SIGTERM, which isn't failure, so suppress failure suggestion
    0|143)
      exit $code;
      ;;
    *)
      echo >&2 "FAILED: A formatter tool exited with code $code"
      if [[ "${mode:-}" == "check" ]]; then
        echo >&2 "Try running '$FIX_CMD' to fix this."
      fi
      ;;
  esac
}

trap on_exit EXIT

function process_args_in_batches() {
    local lang="$1"
    local bin="$2"
    local flags="$3"
    local extensions="$4"
    shift 4
    local args=("$@")

    # Uses up to ARG_MAX - 2k, or 128k, whichever is smaller, characters per
    # command. This was derived from following the defaults from xargs
    # https://www.gnu.org/software/findutils/manual/html_node/find_html/Limiting-Command-Size.html
    max_batch_size=$(getconf ARG_MAX)-2048
    max_batch_size=$((max_batch_size < 128000 ? max_batch_size : 128000))
    
    # Check if there's only one argument and it starts with '@'
    # If so, read the file to get the actual files to format.
    if [ ${#args[@]} -eq 1 ] && [[ "${args[0]}" == @* ]]; then
        local file="${args[0]:1}"  # Strip the '@' symbol
        if [ ! -f "$file" ]; then
            echo "Error: File '$file' not found."
            return 1
        fi
        mapfile -t args < "$file"
        if [ ${#args[@]} -eq 0 ]; then
            echo "Error: No arguments found in the specified file."
            return 1
        fi
    fi

    # If no arguments were passed, still run run-format once
    if [ ${#args[@]} -eq 0 ]; then
        run-format "$lang" "$bin" "$flags" "$extensions"
        return
    fi

    # Format files in batches so that we do not exceed the OS limit for line
    # length when calling subcommands
    local current_batch_size=0
    local current_batch=()
    for arg in "${args[@]}"; do
        if ((current_batch_size + ${#arg} + 1 >= max_batch_size)); then
            # Process current batch
            run-format "$lang" "$bin" "$flags" "$extensions" "${current_batch[@]}"
            current_batch=()
            current_batch_size=0
        fi
        current_batch+=("$arg")
        ((current_batch_size += ${#arg} + 1))  # +1 for space between arguments
    done
    
    # Process any remaining arguments
    if [ -n "$current_batch" ]; then
        run-format "$lang" "$bin" "$flags" "$extensions" "${current_batch[@]}"
    fi
}

# Exports a function that is similar to 'git ls-files'
# ls-files <language> [<file>...]
function ls-files {
    patterns=("$1") && shift;

    if [ "$#" -eq 0 ]; then
        # When the formatter is run with no arguments, we run over "all files in the repo".
        # However, we want to ignore anything that is in .gitignore, is marked for delete, etc.
        # So we use `git ls-files` with some additional care.

        # TODO: determine which staged changes we should format; avoid formatting unstaged changes
        # TODO: try to format only modified regions of the file (where supported)
        files=$(git ls-files -t --cached --modified --other --exclude-standard "${patterns[@]}" "${patterns[@]/#/*/}" | grep -v ^S | cut -f2 -d' ' | {
          grep -vE \
            "^$(git ls-files --deleted)$" \
          || true;
        })
    else
        # When given arguments, they are glob patterns of the superset of files to format.
        # We just need to filter those so we only select files for this language
        # Construct a command-line like
        #  find src/* -name *.ext1 -or -name *.ext2
        find_args=()
        for (( i=0; i<${#patterns[@]}; i++ )); do
          if [[ i -gt 0 ]]; then
            find_args+=('-or')
          fi
          find_args+=("-name" "${patterns[$i]}")
        done
        files=$(find "$@" "${find_args[@]}")
    fi

    if [[ ${disable_git_attribute_checks:-} == true ]]; then
      # files should be returned newline separated to avoid a "File name too long" error
      for file in $files; do
        echo "$file"
      done
      return
    fi

    if [[ $files != "" ]]; then
      git_attributes=$(git check-attr rules-lint-ignored linguist-generated gitlab-generated --stdin <<<"$files")

      # Iterate over each line of the output, files will be reported multiple times, once per attribute checked. To keep from formatting a file twice, we keep track of when the file has changed.
      last_file=""
      attribute_set=false
      while IFS= read -r line; do
          # Extract the file name and attribute values
          file="${line%%:*}"

          if [[ "$file" != "$last_file" ]]; then
              # If no attribute is set for the previous file, add it to the output
              if [[ "$attribute_set" == false && "$last_file" != "" ]]; then
                  echo "$last_file"
              fi
              last_file="$file"
              attribute_set=false
          fi

          # Check if the attribute is set
          if [[ "$line" == *": set" || "$line" == *": true" ]]; then
              attribute_set=true
          fi
      done <<< "$git_attributes"

      # Handle the last file
      if [[ "$attribute_set" == false && "$last_file" != "" ]]; then
          echo "$last_file"
      fi
  fi
}

function time-run {
  local files="$1" && shift
  local bin="$1" && shift
  local lang="$1" && shift
  local silent="$1" && shift
  local TIMEFORMAT="Formatted ${lang} in %lR"

  if [ $silent != 0 ] ; then 2>/dev/null ; fi
  time {
    echo "$files" | tr \\n \\0 | xargs -0 "$bin" "$@" >&2
  }
}

function run-format {
  local lang="$1" && shift
  local bin="$1" && shift
  local args="$1" && shift
  local ext=($1) && shift
  local TIMEFORMAT="Formatted ${lang} in %lR"
  local files=$(ls-files $ext $@)

  if [ -n "$files" ] && [ -n "$bin" ]; then
    case "$lang" in
      'Protocol Buffer')
        time {
          for file in $files; do
            "$bin" $args --path $file >&2
          done
        }
        ;;
      Go)
        # gofmt doesn't produce non-zero exit code so we must check for non-empty output
        # https://github.com/golang/go/issues/24230
        if [[ "${mode:-}" == "check" ]]; then
          GOFMT_OUT=$(mktemp)
          time {
            echo "$files" | tr \\n \\0 | xargs -0 "$bin" $args > "$GOFMT_OUT"
          }
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

# Check if our script is the main entry point, not being sourced by a test
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    bin="$(rlocation $tool)"
    if [ ! -e "$bin" ]; then
        echo >&2 "cannot locate binary $tool"
        exit 1
    fi

    extfile="$(rlocation $extensions)"
    if [ ! -e "$extfile" ]; then
        echo >&2 "cannot locate config $extensions"
        exit 1
    fi

    ext=$(jq -jr ".\"${lang}\"| join(\" \")" < $extfile)
    process_args_in_batches "$lang" "$bin" "${flags:-""}" "$ext" "$@"

    # Handle additional languages for JavaScript and CSS
    if [[ "$lang" == "JavaScript" ]]; then
        for sublang in "JSON" "TSX" "TypeScript" "Vue"; do
            process_args_in_batches "$sublang" "$bin" "${flags:-""}" "$ext" "$@"
        done
    fi
    if [[ "$lang" == "CSS" ]]; then
        for sublang in "Less" "SCSS"; do
            process_args_in_batches "$sublang" "$bin" "${flags:-""}" "$ext" "$@"
        done
    fi
fi

