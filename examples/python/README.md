# Python Formatting and Linting Example

This example demonstrates how to set up formatting and linting for Python code using `rules_lint`.

## Supported Tools

### Formatters

- **Ruff** - Fast Python linter and formatter (can be used for both linting and formatting)

### Linters

- **Ruff** - Fast Python linter (can catch many issues)
- **Pylint** - Comprehensive Python linter
- **semgrep** - A lightweight static analysis for many languages.
- **Flake8** - Style guide enforcement
- **Ty** - Type checker

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure Formatters and Linters

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up each linter aspect

4. Perform formatting and linting using `aspect format` and `aspect lint`

## Example Code

The `src/` directory contains example Python files with intentional violations:

- `unused_import.py` - Contains unused import and format string violations
- `unsupported_operator.py` - Contains type error (unsupported operator)
- `call_non_callable.py` - Contains call to non-callable (ignored in ty.toml)
- `uses_dependency.py` - Demonstrates transitive dependency linting

## Configuration Files

- `.ruff.toml` - Ruff configuration
- `src/ruff.toml` - Local Ruff configuration for src directory
- `src/subdir/ruff.toml` - Path-based Ruff configuration that ignores F401 (unused imports) in subdirectory
- `.pylintrc` - Pylint configuration
- `.flake8` - Flake8 configuration
- `ty.toml` - Ty type checker configuration
