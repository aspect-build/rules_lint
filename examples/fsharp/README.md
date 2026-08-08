# F# Formatting Example

This example demonstrates how to set up formatting for F# code using `rules_lint`.

## Supported Tools

### Formatters

- **Fantomas** - F# source code formatter

Note: No F# linter is currently available in rules_lint.

## Setup

1. Configure `MODULE.bazel` with the required dependencies and .NET toolchain
2. Configure the Paket dependencies in `paket.dependencies` and `3rdparty/nuget/`
3. Configure the formatter

- See `tools/format/BUILD` for how to set up the formatter

4. Perform formatting using `aspect format`

## Example Code

See `src/hello.fs` for a simple example F# program.
