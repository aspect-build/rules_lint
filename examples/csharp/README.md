# C# Formatting Example

This example demonstrates how to set up formatting for C# code using `rules_lint`.

## Supported Tools

### Formatters

- **CSharpier** - Opinionated C# code formatter

Note: No C# linter is currently available in rules_lint.

## Setup

1. Configure `MODULE.bazel` with the required dependencies and .NET toolchain
2. Configure the Paket dependencies in `paket.dependencies` and `3rdparty/nuget/`
3. Configure the formatter

- See `tools/format/BUILD` for how to set up the formatter
- See `3rdparty/nuget/` for Paket dependency setup

4. Perform formatting using `aspect format`

## Example Code

The `src/` directory contains example C# files:

- `hello.cs` - Simple C# file that can be formatted

## Configuration Files

- `paket.dependencies` - Paket dependency file for CSharpier
- `3rdparty/nuget/` - Generated paket files
