# SQL Formatting Example

This example demonstrates how to set up formatting for SQL code using `rules_lint`.

## Supported Tools

### Formatters

- **Prettier** - SQL formatter (via Prettier SQL plugin)

Note: No SQL linter is currently available in rules_lint.

## Setup

1. Configure `MODULE.bazel` with the required dependencies
2. Set up npm dependencies by running `pnpm install` to generate `pnpm-lock.yaml`
3. Configure the formatter

- See `tools/format/BUILD` for how to set up the formatter

4. Perform formatting using `aspect format`

## Example Code

See `src/hello.sql` for a simple example SQL query.
