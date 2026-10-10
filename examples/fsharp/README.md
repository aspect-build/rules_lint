# F# Formatting and Linting Example

This example demonstrates how to set up formatting and linting for F# code using `rules_lint`.

## Supported Tools

### Formatters

- **Fantomas** - F# source code formatter

### Linters

- **FSharpLint** - F# linter

## Setup

1. Configure `MODULE.bazel` with the required dependencies and .NET toolchain
2. Configure the Paket dependencies in `paket.dependencies`, then run `./update-dotnet-deps.sh` to regenerate `3rdparty/nuget/`
3. Configure the tools

- See `tools/format/BUILD` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up the linter, and `fsharplint.json` for its rules

4. Perform formatting using `aspect format`
5. Perform linting using `aspect lint //...`

## Example Code

- `src/hello.fs` - a simple example F# program
- `src/record.fs` - code with FSharpLint violations

## Notes

FSharpLint is normally run on a `.fsproj` or solution, which Bazel builds do not have.
Under Bazel it lints each `.fs` file on its own, so rules that need type information from other
files in the same target may report less than they would for a whole project.
