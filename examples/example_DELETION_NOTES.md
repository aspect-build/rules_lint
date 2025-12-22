# Important Information from legacy monorepo example/ Directory Before Deletion

> **Note**: Most test coverage, code patterns, and examples have been preserved in the language-specific `examples/` directories. This document focuses on unique information that may not be fully captured elsewhere.

## TODOs and FIXMEs

### From `tools/format/BUILD.bazel`:

- **FIXME**: clang-format not hermetic, requires libncurses installed on the machine even when non-interactive
- **FIXME**: java-format (google-java-format) not hermetic - CI error: `com/sun/source/tree/Tree` `java.lang.NoClassDefFoundError`
- **FIXME**: ktfmt not hermetic - CI error: `javax.swing.text.html.HTMLEditorKit$ParserCallback` `java.lang.ClassNotFoundException`
- **FIXME**: swiftformat not hermetic - error while loading shared libraries: `libFoundation.so`

### From `test/machine_outputs/BUILD.bazel`:

- **FIXME**: C++ compile failure on macOS for clang_tidy machine output test
- **FIXME**: PMD report isn't finding any files (also noted in `examples/java/test/BUILD`)
- **TODO**: spotbugs is not working yet - doesn't print source locations (perhaps because it only works from bytecode) (also noted in `examples/java/test/BUILD`)
- **TODO**: add SARIF parsers for keep_sorted and ktlint

### From `lint.sh`:

- **TODO**: Maybe this could be hermetic with `bazel run @bazel_lib//tools:jq` or sth
- Note: jq on windows outputs CRLF which breaks this script (https://github.com/jqlang/jq/issues/92)

## Test Coverage

### Regression Tests:

- **Issue #368**: `eslint_empty_report` test - Regression test for empty ESLint reports
  - ✅ **Already preserved in `examples/nodejs/src/BUILD` and `examples/nodejs/test/BUILD`**
- **Issue #369**: Comment about needing to lint `ts_typings` target, not `//src:ts` which is just a js_library re-export
  - ⚠️ **May need to document this pattern in nodejs example**

> **Note**: Test files, SARIF report testing, generated code handling, and format tests are all preserved in the language-specific examples. See:
>
> - `examples/python/test/` - Python linter tests and SARIF reports
> - `examples/java/test/` - Java linter tests and SARIF reports
> - `examples/nodejs/test/` - NodeJS linter tests and SARIF reports
> - `examples/*/test/` - Similar patterns in other language examples

## Important Code Patterns

> **Note**: Most code patterns are preserved in language-specific examples:
>
> - Special character handling: `examples/nodejs/src/BUILD` (format_test with `(special_char)/[square]/`)
> - Subdirectory-specific config: `examples/python/src/subdir/ruff.toml`
> - Format tests: `examples/go/src/BUILD`, `examples/nodejs/src/BUILD`
> - Linter configuration: Each example has `tools/lint/linters.bzl`

### Unique Multi-language Patterns:

- `tools/format/BUILD.bazel`: Contains `format_test` with `no_sandbox = True` and `workspace` attribute
  - Demonstrates formatting the entire workspace (not just specific files)
  - May be useful for documenting workspace-wide formatting

## Important Comments and References

### Issue References:

- https://github.com/aspect-build/rules_lint/issues/368 - ESLint empty report regression (✅ preserved in nodejs example)
- https://github.com/aspect-build/rules_lint/issues/369 - ESLint target selection issue (⚠️ may need documentation)
- https://github.com/bufbuild/rules_buf/issues/64#issuecomment-2125324929 - Buf allow_comment_ignores
- https://github.com/aspect-build/rules_ts/pull/574#issuecomment-2073632879 - Validation actions
- https://github.com/jqlang/jq/issues/92 - jq CRLF output on Windows
- https://github.com/bazel-contrib/toolchains_llvm/issues/4 - llvm_toolchain doesn't support windows

### Important Notes:

- `BUILD.bazel` line 65-75: Comment about alias NOT causing Loading phase to load tools/BUILD file (important for performance)
  - ⚠️ **This performance note may be worth preserving in documentation**
- `lint.sh` line 12: Note that this is userland code, not a supported public API
- `tools/format/BUILD.bazel` line 119-122: Note about older rules_rust versions needing different rustfmt path

## Utility Functions

- `tools/bzlmod.bzl`: `bzlmod_is_enabled()` function to check if Bzlmod is enabled
  - ⚠️ **May be useful utility to preserve if not already documented**

## Shell Script

- `lint.sh`: Complete shell script that mimics Aspect CLI `bazel lint` command
  - ✅ **Unique - not present in any language-specific examples**
  - Supports `--fix` and `--dry-run` flags
  - Supports `--fail-on-violation` flag
  - Handles Windows vs Linux/Mac differences
  - Extracts and displays lint reports from build events
  - Applies patches when using `--fix`
  - ⚠️ **May be worth preserving as a reference implementation for users who can't use Aspect CLI**
