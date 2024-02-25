#!/usr/bin/env bash
# Template file for a formatter binary. This is expanded by a Bazel action in formatter_binary.bzl
# to produce an actual Bash script.
# Expansions are written in "mustache" syntax like {{interpolate_this}}.

{{BASH_RLOCATION_FUNCTION}}

if [[ -z "$BUILD_WORKSPACE_DIRECTORY" ]]; then
  echo >&2 "$0: FATAL: \$BUILD_WORKSPACE_DIRECTORY not set. This program should be executed under 'bazel run'."
  exit 1
fi

cd $BUILD_WORKSPACE_DIRECTORY

function on_exit {
  code=$?
  case "$code" in
    # return code 143 is the result of SIGTERM, which isn't failure, so suppress failure suggestion
    0|143)
      exit $code;
      ;;
    *)
      echo >&2 "FAILED: A formatter tool exited with code $code"
      echo >&2 "Try running 'bazel run {{fix_target}}' to fix this."
      ;;
  esac
}

trap on_exit EXIT

# ls-files <language> [<file>...]
function ls-files {
    language="$1" && shift;
    # Copied file patterns from
    # https://github.com/github-linguist/linguist/blob/559a6426942abcae16b6d6b328147476432bf6cb/lib/linguist/languages.yml
    # using the ./mirror_linguist_languages.sh tool to transform to Bash code
    case "$language" in
      'C++') patterns=('*.cpp' '*.c++' '*.cc' '*.cp' '*.cppm' '*.cxx' '*.h' '*.h++' '*.hh' '*.hpp' '*.hxx' '*.inc' '*.inl' '*.ino' '*.ipp' '*.ixx' '*.re' '*.tcc' '*.tpp' '*.txx') ;;
      'CSS') patterns=('*.css') ;;
      'Go') patterns=('*.go') ;;
      'HTML') patterns=('*.html' '*.hta' '*.htm' '*.html.hl' '*.inc' '*.xht' '*.xhtml') ;;
      'JSON') patterns=('.all-contributorsrc' '.arcconfig' '.auto-changelog' '.c8rc' '.htmlhintrc' '.imgbotconfig' '.nycrc' '.tern-config' '.tern-project' '.watchmanconfig' 'Pipfile.lock' 'composer.lock' 'deno.lock' 'flake.lock' 'mcmod.info' '*.json' '*.4DForm' '*.4DProject' '*.avsc' '*.geojson' '*.gltf' '*.har' '*.ice' '*.JSON-tmLanguage' '*.jsonl' '*.mcmeta' '*.tfstate' '*.tfstate.backup' '*.topojson' '*.webapp' '*.webmanifest' '*.yy' '*.yyp') ;;
      'Java') patterns=('*.java' '*.jav' '*.jsh') ;;
      'JavaScript') patterns=('Jakefile' '*.js' '*._js' '*.bones' '*.cjs' '*.es' '*.es6' '*.frag' '*.gs' '*.jake' '*.javascript' '*.jsb' '*.jscad' '*.jsfl' '*.jslib' '*.jsm' '*.jspre' '*.jss' '*.jsx' '*.mjs' '*.njs' '*.pac' '*.sjs' '*.ssjs' '*.xsjs' '*.xsjslib') ;;
      'Jsonnet') patterns=('*.jsonnet' '*.libsonnet') ;;
      'Kotlin') patterns=('*.kt' '*.ktm' '*.kts') ;;
      'Markdown') patterns=('contents.lr' '*.md' '*.livemd' '*.markdown' '*.mdown' '*.mdwn' '*.mkd' '*.mkdn' '*.mkdown' '*.ronn' '*.scd' '*.workbook') ;;
      'Protocol Buffer') patterns=('*.proto') ;;
      'Python') patterns=('.gclient' 'DEPS' 'SConscript' 'SConstruct' 'wscript' '*.py' '*.cgi' '*.fcgi' '*.gyp' '*.gypi' '*.lmi' '*.py3' '*.pyde' '*.pyi' '*.pyp' '*.pyt' '*.pyw' '*.rpy' '*.spec' '*.tac' '*.wsgi' '*.xpy') ;;
      'SQL') patterns=('*.sql' '*.cql' '*.ddl' '*.inc' '*.mysql' '*.prc' '*.tab' '*.udf' '*.viw') ;;
      'Scala') patterns=('*.scala' '*.kojo' '*.sbt' '*.sc') ;;
      'Shell') patterns=('.bash_aliases' '.bash_functions' '.bash_history' '.bash_logout' '.bash_profile' '.bashrc' '.cshrc' '.flaskenv' '.kshrc' '.login' '.profile' '.zlogin' '.zlogout' '.zprofile' '.zshenv' '.zshrc' '9fs' 'PKGBUILD' 'bash_aliases' 'bash_logout' 'bash_profile' 'bashrc' 'cshrc' 'gradlew' 'kshrc' 'login' 'man' 'profile' 'zlogin' 'zlogout' 'zprofile' 'zshenv' 'zshrc' '*.sh' '*.bash' '*.bats' '*.cgi' '*.command' '*.fcgi' '*.ksh' '*.sh.in' '*.tmux' '*.tool' '*.trigger' '*.zsh' '*.zsh-theme') ;;
      'Starlark') patterns=('BUCK' 'BUILD' 'BUILD.bazel' 'MODULE.bazel' 'Tiltfile' 'WORKSPACE' 'WORKSPACE.bazel' '*.bzl' '*.star') ;;
      'Swift') patterns=('*.swift') ;;
      'TSX') patterns=('*.tsx') ;;
      'TypeScript') patterns=('*.ts' '*.cts' '*.mts') ;;
      'YAML') patterns=('*.yml' '*.yaml' '.clang-format' '.clang-tidy' '.gemrc') ;;

      # Note: terraform fmt cannot handle all HCL files such as .terraform.lock
      # "Only .tf and .tfvars files can be processed with terraform fmt"
      # so we define a custom language here instead of 'HCL' from github-linguist definition for the language.
      # TODO: we should probably use https://terragrunt.gruntwork.io/docs/reference/cli-options/#hclfmt instead
      # which does support the entire HCL language FWICT
      'Terraform') patterns=('*.tf' '*.tfvars') ;;

      *)
        echo >&2 "Internal error: unknown language $language"
        exit 1
        ;;
    esac

    if [ "$#" -eq 0 ]; then
        # When the formatter is run with no arguments, we run over "all files in the repo".
        # However, we want to ignore anything that is in .gitignore, is marked for delete, etc.
        # So we use `git ls-files` with some additional care.

        # TODO: determine which staged changes we should format; avoid formatting unstaged changes
        # TODO: try to format only modified regions of the file (where supported)
        git ls-files --cached --modified --other --exclude-standard "${patterns[@]}" "${patterns[@]/#/*/}" | {
          grep -vE "^$(git ls-files --deleted)$" || true;
        }
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
        find "$@" "${find_args[@]}"
    fi
}

# Define the flags for the tools based on the mode of operation
mode=fix
if [ "${1:-}" == "--mode" ]; then
  readonly mode=$2
  shift 2
fi

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
   clangformatmode="--style=file --fallback-style=none --dry-run -Werror"
   yamlfmtmode="-lint"
   ;;
 fix)
   swiftmode=""
   prettiermode="--write"
   # Force exclusions in the configuration file to be honored even when file paths are supplied
   # as command-line arguments; see
   # https://github.com/astral-sh/ruff/discussions/5857#discussioncomment-6583943
   ruffmode="format --force-exclude"
   # NB: apply-ignore added in https://github.com/mvdan/sh/issues/1037
   shfmtmode="-w --apply-ignore"
   javamode="--replace"
   ktmode=""
   gofmtmode="-w"
   bufmode="format -w"
   tfmode=""
   jsonnetmode="--in-place"
   scalamode=""
   clangformatmode="-style=file --fallback-style=none -i"
   yamlfmtmode=""
   ;;
 *) echo >&2 "unknown mode $mode";;
esac

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
  local fmtname="$1" && shift
  local bin="$1" && shift
  local args="$1" && shift
  local tuser
  local tsys

  local files=$(ls-files "$lang" $@)
  if [ -n "$files" ] && [ -n "$bin" ]; then
    echo "Formatting ${lang} with ${fmtname}..."
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
          ( export JAVA_RUNFILES="${RUNFILES_MANIFEST_FILE%_manifest}" ; time-run "$files" "$bin" "$lang" 0 $args )
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

# Run each supplied formatter over the files it owns

run-format Starlark Buildifier "$(rlocation {{buildifier}})" "-mode=$mode" $@
run-format Markdown Prettier "$(rlocation {{prettier-md}})" "$prettiermode" $@
run-format JSON Prettier "$(rlocation {{prettier}})" "$prettiermode" $@
run-format JavaScript Prettier "$(rlocation {{prettier}})" "$prettiermode" $@
run-format CSS Prettier "$(rlocation {{prettier}})" "$prettiermode" $@
run-format HTML Prettier "$(rlocation {{prettier}})" "$prettiermode" $@
run-format TypeScript Prettier "$(rlocation {{prettier}})" "$prettiermode" $@
run-format TSX Prettier "$(rlocation {{prettier}})" "$prettiermode" $@
run-format SQL Prettier "$(rlocation {{prettier-sql}})" "$prettiermode" $@
run-format Python Ruff "$(rlocation {{ruff}})" "$ruffmode" $@
run-format Terraform "terraform fmt" "$(rlocation {{terraform-fmt}})" "fmt $tfmode" $@
run-format Jsonnet jsonnetfmt "$(rlocation {{jsonnetfmt}})" "$jsonnetmode" $@
run-format Java java-format "$(rlocation {{java-format}})" "$javamode" $@
run-format Kotlin ktfmt "$(rlocation {{ktfmt}})" "$ktmode" $@
run-format Scala scalafmt "$(rlocation {{scalafmt}})" "$scalamode" $@
run-format Go gofmt "$(rlocation {{gofmt}})" "$gofmtmode" $@
run-format C++ clang-format "$(rlocation {{clang-format}})" "$clangformatmode" $@
run-format Shell shfmt "$(rlocation {{shfmt}})" "$shfmtmode" $@
run-format Swift swiftfmt "$(rlocation {{swiftformat}})" "$swiftmode" $@
run-format 'Protocol Buffer' buf "$(rlocation {{buf}})" "$bufmode" $@
run-format YAML yamlfmt "$(rlocation {{yamlfmt}})" "$yamlfmtmode" $@
