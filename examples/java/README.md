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

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "rules_java", version = "8.5.0")
bazel_dep(name = "rules_jvm_external", version = "6.5")
```

### 2. Configure Formatters and Linters

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up each linter aspect

### 3. Run Formatters and Linters

With Aspect CLI:

```bash
# Format code
bazel format //src:all

# Lint code
bazel lint //src:all
```

Without Aspect CLI:

```bash
# Format code
bazel run //tools/format -- src:all

# Lint code (use lint.sh script)
./lint.sh src:all
```

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
