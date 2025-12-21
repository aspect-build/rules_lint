# Keep-Sorted Linting Example

This example demonstrates how to set up the [keep-sorted](https://github.com/google/keep-sorted) linter using `rules_lint`.

Keep-sorted is a tool that ensures code blocks marked with `// keep-sorted start` and `// keep-sorted end` comments are kept in sorted order.

## Supported Tools

### Linters

- **keep-sorted** - Ensures marked code blocks are kept in sorted order

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure Go SDK
4. Fetch keep-sorted Dependency (requires `--experimental_isolated_extension_usages` in `.bazelrc`)
5. Configure Linters

- See `tools/lint/linters.bzl` for how to set up the linter aspect

6. Perform linting using `aspect lint`

## Example Code

See `src/example.go` for a simple example demonstrating keep-sorted markers.
