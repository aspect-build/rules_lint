# Go Formatting Example

This example demonstrates how to set up formatting for Go code using `rules_lint`.

## Supported Tools

### Formatters

- **gofumpt** - Stricter version of gofmt with additional formatting rules

Note: You can also use standard `gofmt` instead of `gofumpt` if you prefer.

## Setup

1. Configure `MODULE.bazel` with the required dependencies
2. Configure the formatter

- See `tools/format/BUILD` for how to set up the formatter

3. Perform formatting using `aspect format`

## Example Code

See `src/hello.go` for a simple example Go program.
