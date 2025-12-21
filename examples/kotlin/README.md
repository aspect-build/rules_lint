# Kotlin Formatting and Linting Example

This example demonstrates how to set up formatting and linting for Kotlin code using `rules_lint`.

## Supported Tools

### Formatters

- **ktfmt** - Code formatter for Kotlin

### Linters

- **ktlint** - Linter for Kotlin

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "rules_kotlin", version = "1.9.0")
```

### 2. Configure Format Tools

Add ktfmt to your format tools:

```starlark
format_tools = use_extension("@aspect_rules_lint//format:extensions.bzl", "format_tools")
format_tools.ktfmt()
use_repo(format_tools, "ktfmt")
```

### 3. Configure Lint Tools

Add ktlint to your lint tools:

```starlark
lint_tools = use_extension("@aspect_rules_lint//lint:extensions.bzl", "lint_tools")
lint_tools.ktlint()
use_repo(lint_tools, "com_github_pinterest_ktlint")
```

### 4. Run Formatters

With Aspect CLI:

```bash
# Format code
bazel format //src:all
```

Without Aspect CLI:

```bash
# Format code
bazel run //tools/format -- src:all
```

### 5. Run Linters

With Aspect CLI:

```bash
# Lint code
bazel lint //src:all
```

Without Aspect CLI:

```bash
# Lint code
./lint.sh //src:all
```

## Example Code

The `src/` directory contains example Kotlin files:

- `hello.kt` - Simple Kotlin file with intentional violations

## Configuration Files

- `ktlint-baseline.xml` - ktlint baseline file for suppressing known violations
- `.editorconfig` - EditorConfig file (ktlint respects this)
