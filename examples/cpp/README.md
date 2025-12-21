# C++ Formatting and Linting Example

This example demonstrates how to set up formatting and linting for C++ code using `rules_lint`.

## Supported Tools

### Formatters

- **clang-format** - C++ and CUDA code formatter

### Linters

- **clang-tidy** - C++ static analysis tool
- **cppcheck** - C++ static analysis tool

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "rules_cc", version = "0.0.9")
bazel_dep(name = "toolchains_llvm", version = "1.1.2")
```

### 2. Configure Formatters and Linters

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up each linter aspect

### 3. Run Formatters and Linters

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
bazel run //tools/format -- src:all

# Lint code (use lint.sh script)
./lint.sh src:all
```

## Example Code

The `src/` directory contains example C++ files with intentional violations:

- `hello.cpp` - Contains clang-tidy violations (atoi usage, system calls, memory issues)
- `hello.cu` - CUDA file (formatted with clang-format)
- `src/cpp/` - More complex C++ project structure with libraries and binaries

## Configuration Files

- `.clang-tidy` - clang-tidy configuration
- `src/cpp/lib/get/.clang-tidy` - Directory-specific clang-tidy overrides
