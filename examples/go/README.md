# Go Formatting Example

This example demonstrates how to set up formatting for Go code using `rules_lint`.

## Supported Tools

### Formatters

- **gofumpt** - Stricter version of gofmt with additional formatting rules

Note: You can also use standard `gofmt` instead of `gofumpt` if you prefer.

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "rules_go", version = "0.52.0")
```

### 2. Configure Go SDK

Add the Go SDK extension:

```starlark
go_sdk = use_extension("@io_bazel_rules_go//go:extensions.bzl", "go_sdk")
go_sdk.download(
    name = "go_sdk",
    version = "1.23.5",
)
use_repo(go_sdk, "go_sdk")
```

### 3. Configure Formatter

In `tools/format/BUILD.bazel`, set up the formatter:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

format_multirun(
    name = "format",
    go = "@aspect_rules_lint//format:gofumpt",
    # Or use standard gofmt:
    # go = "@go_sdk//:bin/gofmt",
    visibility = ["//:__subpackages__"],
)
```

### 4. Define Go Targets

In your `BUILD.bazel` files, define Go targets as usual:

```starlark
load("@io_bazel_rules_go//go:def.bzl", "go_binary")

go_binary(
    name = "hello",
    srcs = ["hello.go"],
)
```

## Usage

### Format Code

Format all Go files:

```bash
bazel run //tools/format:format
```

Format specific files:

```bash
bazel run //tools/format:format -- hello.go
```

### Verify Formatting

Add a `format_test` to ensure files are formatted:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_test")

format_test(
    name = "format_files_test",
    srcs = ["hello.go"],
)
```

Run the test:

```bash
bazel test //src:format_files_test
```

## Example Code

See `src/hello.go` for a simple example Go program.
