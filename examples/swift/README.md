# Swift Formatting Example

This example demonstrates how to set up formatting for Swift code using `rules_lint`.

## Supported Tools

### Formatters

- **SwiftFormat** - Code formatter for Swift

Note: No Swift linter is currently available in rules_lint.

## Setup

1. Configure `MODULE.bazel` with the required dependencies
2. Add SwiftFormat and configure the formatter

- See `tools/format/BUILD` for how to set up the formatter

3. Perform formatting using `aspect format`

## Example Code

See `src/hello.swift` for a simple example Swift file.
