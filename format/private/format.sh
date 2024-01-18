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
  if [[ $code != 0 ]]; then
    echo >&2 "FAILED: A formatter tool exited with code $code"
    echo >&2 "Try running 'bazel run {{fix_target}}' to fix this."
  fi
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
      'HCL') patterns=('*.hcl' '*.nomad' '*.tf' '*.tfvars' '*.workflow') ;;
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
        git ls-files --cached --modified --other --exclude-standard ${patterns[@]} | {
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
   clangformatmode="--style=file --fallback-style=none --dry-run"
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
   clangformatmode="-style=file --fallback-style=none -i"
   ;;
 *) echo >&2 "unknown mode $mode";;
esac

# Run each supplied formatter over the files it owns
# TODO: run them concurrently, not serial

files=$(ls-files Starlark $@)
bin=$(rlocation {{buildifier}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting Starlark with Buildifier..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin -mode="$mode"
fi

files=$(ls-files Markdown $@)
bin=$(rlocation {{prettier-md}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting Markdown with Prettier..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $prettiermode
fi

files=$(ls-files JavaScript $@)
bin=$(rlocation {{prettier}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting JavaScript with Prettier..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $prettiermode
fi

files=$(ls-files CSS $@)
bin=$(rlocation {{prettier}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting CSS with Prettier..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $prettiermode
fi

files=$(ls-files HTML $@)
bin=$(rlocation {{prettier}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting HTML with Prettier..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $prettiermode
fi

files=$(ls-files TypeScript $@)
bin=$(rlocation {{prettier}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting TypeScript with Prettier..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $prettiermode
fi

files=$(ls-files TSX $@)
bin=$(rlocation {{prettier}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting TSX with Prettier..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $prettiermode
fi

files=$(ls-files SQL $@)
bin=$(rlocation {{prettier-sql}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Running SQL with Prettier..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $prettiermode
fi

files=$(ls-files Python $@)
bin=$(rlocation {{ruff}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting Python with ruff..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $ruffmode
fi

files=$(ls-files HCL $@)
bin=$(rlocation {{terraform-fmt}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting Hashicorp Config Language with terraform fmt..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin fmt $tfmode
fi

files=$(ls-files Jsonnet $@)
bin=$(rlocation {{jsonnetfmt}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting Jsonnet with jsonnetfmt..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $jsonnetmode
fi

files=$(ls-files Java $@)
bin=$(rlocation {{java-format}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting Java with java-format..."
  # Setting JAVA_RUNFILES to work around https://github.com/bazelbuild/bazel/issues/12348
  echo "$files" | tr \\n \\0 | JAVA_RUNFILES="${RUNFILES_MANIFEST_FILE%_manifest}" xargs -0 $bin $javamode
fi

files=$(ls-files Kotlin $@)
bin=$(rlocation {{ktfmt}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting Kotlin with ktfmt..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $ktmode
fi

files=$(ls-files Scala $@)
bin=$(rlocation {{scalafmt}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting Scala with scalafmt..."
  # Setting JAVA_RUNFILES to work around https://github.com/bazelbuild/bazel/issues/12348
  echo "$files" | tr \\n \\0 | JAVA_RUNFILES="${RUNFILES_MANIFEST_FILE%_manifest}" xargs -0 $bin $scalamode
fi

files=$(ls-files Go $@)
bin=$(rlocation {{gofmt}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting Go with gofmt..."
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

files=$(ls-files C++ $@)
bin=$(rlocation {{clang-format}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting C/C++ with clang-format..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $clangformatmode
fi

files=$(ls-files Shell $@)
bin=$(rlocation {{shfmt}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting Shell with shfmt..."
  echo "$files" | tr \\n \\0 | xargs -0 $bin $shfmtmode
fi

files=$(ls-files Swift $@)
bin=$(rlocation {{swiftformat}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  # swiftformat itself prints Running SwiftFormat...
  echo "$files" | tr \\n \\0 | xargs -0 $bin $swiftmode
fi

files=$(ls-files 'Protocol Buffer' $@)
bin=$(rlocation {{buf}})
if [ -n "$files" ] && [ -n "$bin" ]; then
  echo "Formatting Protobuf with buf..."
  for file in $files; do
    $bin $bufmode $file
  done
fi
