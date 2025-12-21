# Swift Formatting Example

This example demonstrates how to set up formatting for Swift code using `rules_lint`.

## Supported Tools

### Formatters

- **SwiftFormat** - Code formatter for Swift

Note: No Swift linter is currently available in rules_lint.

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "bazel_features", version = "1.29.0")
```

### 2. Configure Format Tools

Add swiftformat to your format tools:

```starlark
format_tools = use_extension("@aspect_rules_lint//format:extensions.bzl", "tools")
format_tools.swiftformat()
use_repo(format_tools, "swiftformat", "swiftformat_mac")
```

### 3. Configure Formatter

In `tools/format/BUILD.bazel`, set up the formatter:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

alias(
    name = "swiftformat",
    actual = select({
        "@bazel_tools//src/conditions:linux": "@swiftformat",
        "@bazel_tools//src/conditions:darwin": "@swiftformat_mac",
    }),
)

format_multirun(
    name = "format",
    swift = ":swiftformat",
    visibility = ["//:__subpackages__"],
)
```

## Usage

### Format Code

Format all Swift files:

```bash
bazel run //tools/format:format
```

Format specific files:

```bash
bazel run //tools/format:format -- hello.swift
```

## Example Code

See `src/hello.swift` for a simple example Swift file.
