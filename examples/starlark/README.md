# Starlark Linting Example

This example demonstrates how to lint Starlark files with `rules_lint` using Buildifier.

## Supported Tools

### Linters

- **Buildifier** - Starlark linter and formatter for Bazel `BUILD`, `MODULE`, `.bzl`, and custom Starlark files

## Setup

1. Configure `MODULE.bazel` with the required dependencies
2. Create the `MODULE.aspect` file to register CLI tasks
3. Configure the Buildifier linter in `tools/lint/linters.bzl`
4. Run linting with `aspect lint`

This example uses the `buildifier_prebuilt` module and passes `@buildifier_prebuilt//:buildifier`
to the linter aspect.

## Example Targets

This example shows two ways to opt Starlark files into linting:

- `src:defs` uses `bzl_library`, which is linted by default
- `src:tagged_starlark` is a generic target tagged with `starlark`
