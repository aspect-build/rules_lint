# Ruby Linting Example

This example demonstrates how to set up linting for Ruby code using `rules_lint`.

## Supported Tools

### Linters

- **RuboCop** - Ruby static code analyzer
- **Standard Ruby** - Zero-configuration Ruby style guide and linter based on RuboCop

Note: No Ruby formatter is currently available in rules_lint.

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "rules_ruby", version = "0.21.1")
```

### 2. Configure Linters

- See `tools/lint/linters.bzl` for how to set up each linter aspect

### 3. Run Linters

With Aspect CLI:

```bash
# Lint code
bazel lint //src:all
```

Without Aspect CLI:

```bash
# Lint code (use lint.sh script)
./lint.sh src:all
```

## Example Code

The `src/` directory contains example Ruby files with intentional violations:

- `hello.rb` - Contains RuboCop and Standard Ruby violations (unused variables, line length, indentation, string literals, trailing commas)

## Configuration Files

- `.rubocop.yml` - RuboCop configuration
- `.standard.yml` - Standard Ruby configuration
- `Gemfile` - Ruby gem dependencies
- `.ruby-version` - Ruby version specification
