# TOML Formatting and Linting Example

This example demonstrates how to set up formatting and linting for TOML files using `rules_lint`.

## Supported Tools

### Formatters

- **Taplo** - TOML formatter

### Linters

- **Taplo** - TOML linter

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure Taplo (shared by formatting and linting)
4. Configure Formatters and Linters

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up the linter aspect

5. Perform formatting and linting using `aspect format` and `aspect lint`

## Example Code

The `src/` directory contains example TOML files:

- `hello.toml` - A TOML file with formatting issues
- `bad.toml` - A TOML file with duplicate keys for linting

## Configuration Files

- `.taplo.toml` - Shared Taplo configuration
