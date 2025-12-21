# C# Formatting Example

This example demonstrates how to set up formatting for C# code using `rules_lint`.

## Supported Tools

### Formatters

- **CSharpier** - Opinionated C# code formatter

Note: No C# linter is currently available in rules_lint.

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure Formatters

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `3rdparty/nuget/` for paket dependency setup

4. Perform formatting using `aspect format`

## Example Code

The `src/` directory contains example C# files:

- `hello.cs` - Simple C# file that can be formatted

## Configuration Files

- `paket.dependencies` - Paket dependency file for CSharpier
- `3rdparty/nuget/` - Generated paket files
