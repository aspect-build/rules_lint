# Java Formatting and Linting Example

This example demonstrates how to set up formatting and linting for Java code using `rules_lint`.

## Supported Tools

### Formatters

- **Google Java Format** - Code formatter that follows Google's Java style guide

### Linters

- **Checkstyle** - Style and coding standard checker
- **PMD** - Source code analyzer
- **SpotBugs** - Static analysis tool for finding bugs

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure Formatters and Linters

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up each linter aspect

4. Perform formatting and linting using `aspect format` and `aspect lint`

## Example Code

The `src/` directory contains example Java files with intentional violations:

- `Foo.java` - Contains SpotBugs violations (null pointer, dead store, resource leak)
- `Bar.java` - Contains Checkstyle violations (line length, unused imports)
- `FileReaderUtil.java` - Helper class used by Foo

## Configuration Files

- `checkstyle.xml` - Checkstyle configuration
- `checkstyle-suppressions.xml` - Suppressions for Checkstyle
- `pmd.xml` - PMD ruleset configuration
- `spotbugs-exclude.xml` - SpotBugs exclusion filter
