# F# Formatting Example

This example demonstrates how to set up formatting for F# code using `rules_lint`.

## Supported Tools

### Formatters

- **Fantomas** - F# source code formatter

Note: No F# linter is currently available in rules_lint.

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure .NET Toolchain
4. Configure Paket Dependencies (see `3rdparty/nuget/` for setup)
5. Configure Formatters

- See `tools/format/BUILD.bazel` for how to set up the formatter

6. Perform formatting using `aspect format`

## Example Code

See `src/hello.fs` for a simple example F# program.
