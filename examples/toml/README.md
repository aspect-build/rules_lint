# TOML Formatting Example

This example demonstrates how to set up formatting for TOML files using `rules_lint`.

## Supported Tools

### Formatters

- **Taplo** - TOML formatter

Note: No TOML linter is currently available in rules_lint.

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure Format Tools (add taplo)
4. Configure Formatters

- See `tools/format/BUILD.bazel` for how to set up the formatter

5. Perform formatting using `aspect format`

## Example Code

See `src/hello.toml` for a simple example TOML file.
