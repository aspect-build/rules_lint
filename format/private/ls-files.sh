# Exports a function that is similar to 'git ls-files'
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
        files=$(git ls-files --cached --modified --other --exclude-standard "${patterns[@]}" "${patterns[@]/#/*/}" | {
          grep -vE \
            "^$(git ls-files --deleted)$" \
          || true;
        })
        if [[ $files != "" ]]; then
            git_attributes=$(git check-attr -a -- $files)
            for file in $files; do
                # Check if any of the attributes we ignore are set for this file.
                if ! grep -qE "(^| )$file: (rules-lint-ignored|linguist-generated|gitlab-generated): set($| )" <<< $git_attributes; then
                    echo $file
                fi
            done
        fi
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
