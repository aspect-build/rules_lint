# Kotlin Formatting and Linting Example

This example demonstrates how to set up formatting and linting for Kotlin code using `rules_lint`.

## Supported Tools

### Formatters

- **ktfmt** - Code formatter for Kotlin

### Linters

- **ktlint** - Linter for Kotlin

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure Format Tools (add ktfmt)
4. Configure Lint Tools (add ktlint)
5. Configure Formatters and Linters

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up each linter aspect

6. Perform formatting and linting using `aspect format` and `aspect lint`

## Example Code

The `src/` directory contains example Kotlin files:

- `hello.kt` - Simple Kotlin file with intentional violations

## Configuration Files

- `ktlint-baseline.xml` - ktlint baseline file for suppressing known violations
- `.editorconfig` - EditorConfig file (ktlint respects this)
