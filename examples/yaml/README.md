# YAML Formatting and Linting Example

This example demonstrates how to set up formatting and linting for YAML files using `rules_lint`.

## Supported Tools

### Formatters

- **yamlfmt** - YAML formatter

### Linters

- **yamllint** - YAML linter

## Setup

1. Configure MODULE.bazel with required dependencies
2. Configure the Aspect CLI lint task in `.aspect/config.axl`
3. Configure Python Dependencies (set up pip for yamllint)
4. Configure Formatters and Linters

- See `tools/format/BUILD` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up the linter aspect

5. Perform formatting and linting using `aspect format` and `aspect lint`

## Example Code

See `src/config.yaml` for a simple example YAML file.
