# Python Formatting and Linting Example

This example demonstrates how to set up formatting and linting for Python code using `rules_lint`.

## Supported Tools

### Formatters

- **Ruff** - Fast Python linter and formatter (can be used for both linting and formatting)

### Linters

- **Ruff** - Fast Python linter (can catch many issues)
- **Pylint** - Comprehensive Python linter
- **Flake8** - Style guide enforcement
- **Ty** - Type checker

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "rules_python", version = "0.26.0")
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
