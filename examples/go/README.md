# Go Formatting Example

This example demonstrates how to set up formatting for Go code using `rules_lint`.

## Supported Tools

### Formatters

- **gofumpt** - Stricter version of gofmt with additional formatting rules

Note: You can also use standard `gofmt` instead of `gofumpt` if you prefer.

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure Formatters

- See `tools/format/BUILD.bazel` for how to set up the formatter

4. Perform formatting using `aspect format`

## Example Code

See `src/hello.go` for a simple example Go program.
