# Shell Formatting and Linting Example

This example demonstrates how to set up formatting and linting for shell scripts using `rules_lint`.

## Supported Tools

### Formatters

- **shfmt** - Shell formatter that formats shell programs

### Linters

- **ShellCheck** - Static analysis tool for shell scripts

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure Formatters and Linters

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up the linter aspect

3. Create `.shellcheckrc` configuration file
4. Perform formatting and linting using `aspect format` and `aspect lint`

## Example Code

See `src/hello.sh` for a simple example shell script with intentional violations to demonstrate linting.
