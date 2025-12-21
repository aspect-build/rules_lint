# C# Formatting Example

This example demonstrates how to set up formatting for C# code using `rules_lint`.

## Supported Tools

### Formatters

- **CSharpier** - Opinionated C# code formatter

Note: No C# linter is currently available in rules_lint.

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "rules_dotnet", version = "0.20.5")
```

### 2. Configure Formatters

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `3rdparty/nuget/` for paket dependency setup

### 3. Run Formatters

With Aspect CLI:

```bash
# Format code
bazel format //src:all
```

Without Aspect CLI:

```bash
# Format code
bazel run //tools/format -- src:all
```

## Example Code

The `src/` directory contains example C# files:

- `hello.cs` - Simple C# file that can be formatted

## Configuration Files

- `paket.dependencies` - Paket dependency file for CSharpier
- `3rdparty/nuget/` - Generated paket files
