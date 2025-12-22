# Terraform Formatting Example

This example demonstrates how to set up formatting for Terraform (HCL) code using `rules_lint`.

## Supported Tools

### Formatters

- **terraform** - Official Terraform formatter

Note: No Terraform linter is currently available in rules_lint.

## Usage

### Format Code

Format all Terraform files:

```bash
bazel run //tools/format:format
```

Format specific files:

```bash
bazel run //tools/format:format -- hello.tf
```
