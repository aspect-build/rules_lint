# Clang-tidy PR

(temporary file, not to be included in final merge)

I'm attempting to integrate clang-tidy with rules_lint, by integrating some of the aspect approaches from
bazel_clang_tidy into this linter framework. The idea of integrating these linters has been suggested by
maintainers of both repos (https://github.com/erenon/bazel_clang_tidy/issues/35)

## Windows setup
```
copy clang-tidy.exe into examples/tools/lint
del examples\\.bazeliskrc (aspect-cli does not support windows)
BAZEL_SH=c:\msys64\usr\bin\bash.exe # git bash doesn't seem to work
BAZEL_VC=c:\apps\MVS16\VC
```

## Example commands
Run on a binary
```
cd example
bazel build //src/cpp/main:hello-world --config=clang-tidy
```

Run with raw options, no config (this is exactly the same as above)
```
bazel build //src/cpp/main:hello-world --aspects=//tools/lint:linters.bzl%clang_tidy --output_groups=rules_lint_report
```

See clang-tidy command line for each invokation
```
bazel build //src/cpp/main:hello-world --config=clang-tidy -s
```

Run on a cc_library
```
bazel build //src/cpp/lib:hello-time --config=clang-tidy -s
```

## Questions
- clang-tidy handles only a single source file at a time. This is different to all the other linters currently supported. What is the best way to structure this code in clang_tidy.bzl? Pass one file to each invokation of clang_tidy_action? Or loop inside clang_tidy_action?
- Any other inputs?

