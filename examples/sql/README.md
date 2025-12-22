# SQL Formatting Example

This example demonstrates how to set up formatting for SQL code using `rules_lint`.

## Supported Tools

### Formatters

- **Prettier** - SQL formatter (via Prettier SQL plugin)

Note: No SQL linter is currently available in rules_lint.

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Set up npm dependencies (run `pnpm install` to generate `pnpm-lock.yaml`)
4. Configure Formatters

- See `tools/format/BUILD.bazel` for how to set up the formatter

5. Perform formatting using `aspect format`

## Example Code

See `src/hello.sql` for a simple example SQL query.
