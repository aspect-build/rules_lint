# Terraform Example

This example demonstrates how to set up formatting and linting for Terraform (HCL) code using `rules_lint`.

## Supported Tools

### Formatters

- **terraform** - Official Terraform formatter

### Linters

- **tflint** - Pluggable Terraform linter

## Usage

### Format Code

Format all Terraform files:

```bash
bazel run //tools/format:format
```

### Lint Code

Lint Terraform files via the aspect:

```bash
bazel lint //src:example
```

Or using vanilla Bazel:

```bash
bazel build //src:example --aspects=//tools/lint:linters.bzl%tflint --output_groups=rules_lint_human
```
