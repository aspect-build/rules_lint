# YAML Formatting and Linting Example

This example demonstrates how to set up formatting and linting for YAML files using `rules_lint`.

## Supported Tools

### Formatters

- **yamlfmt** - YAML formatter

### Linters

- **yamllint** - YAML linter

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "bazel_features", version = "1.29.0")
bazel_dep(name = "rules_python", version = "0.26.0")
```

### 2. Configure Python Dependencies

Set up Python pip dependencies for yamllint:

```starlark
pip = use_extension("@rules_python//python/extensions:pip.bzl", "pip")
pip.parse(
    name = "pip",
    requirements_lock = "//:requirements.txt",
)
use_repo(pip, "pip")
```

### 3. Configure Formatter and Linter

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up the linter aspect

### 4. Run Formatters and Linters

With Aspect CLI:

```bash
# Format code
bazel format //src:all

# Lint code
bazel lint //src:all
```

Without Aspect CLI:

```bash
# Format code
bazel run //tools/format:format

# Lint code (use lint.sh script)
./lint.sh src:all
```

## Example Code

See `src/config.yaml` for a simple example YAML file.
