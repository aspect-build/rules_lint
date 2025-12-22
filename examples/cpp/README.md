# C++ Formatting and Linting Example

This example demonstrates how to set up formatting and linting for C++ code using `rules_lint`.

## Supported Tools

### Formatters

- **clang-format** - C++ and CUDA code formatter

### Linters

- **clang-tidy** - C++ static analysis tool
- **cppcheck** - C++ static analysis tool

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure Formatters and Linters

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up each linter aspect

4. Perform formatting and linting using `aspect format` and `aspect lint`

## Example Code

The `src/` directory contains example C++ files with intentional violations:

- `hello.cpp` - Contains clang-tidy violations (atoi usage, system calls, memory issues)
- `hello.cu` - CUDA file (formatted with clang-format)
- `src/cpp/` - More complex C++ project structure with libraries and binaries

## Configuration Files

- `.clang-tidy` - clang-tidy configuration
- `src/cpp/lib/get/.clang-tidy` - Directory-specific clang-tidy overrides
