# SQL Formatting and Linting Example

This example demonstrates how to set up formatting and linting for SQL code using `rules_lint`.

The lint integration requires SQLFluff 4.3.0 or newer.

## Supported Tools

### Formatters

- **Prettier** - SQL formatter (via Prettier SQL plugin)

### Linters

- **SQLFluff** - SQL linter and auto-fixer

## Setup

1. Configure `MODULE.bazel` with the required dependencies
2. Set up the Python dependency lock (run `bazel run //:requirements.update`)
3. Set up npm dependencies (run `pnpm install` to generate `pnpm-lock.yaml`)
4. Configure the tools

- See `tools/format/BUILD` for the Prettier formatter
- See `tools/lint/BUILD` for the SQLFluff binary
- See `tools/lint/linters.bzl` for how to set up the linter
- See `.aspect/config.axl` for `aspect lint` registration
- See `.bazelrc` for direct `bazel build --config=lint` registration
- See `.sqlfluff` for the SQL dialect and lint rules
- See `src/BUILD` for nested configurations and a Jinja helper declared as target-local `data`

5. Run `aspect format` or `aspect lint -- //...`

## Example Code

See `src/hello.sql` for a simple query with intentional SQLFluff findings. `src/query.sql.j2`
imports a Jinja helper supplied through its Bazel target's `data` attribute.

Templater files needed by only some SQL targets should be declared in those targets' `data`.
Aspect-level `data` is intended for files shared by every linted target.
