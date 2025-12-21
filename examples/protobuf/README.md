# Protobuf Formatting and Linting Example

This example demonstrates how to set up formatting and linting for Protocol Buffer (protobuf) files using `rules_lint`.

## Supported Tools

### Formatters

- **Buf** - Modern protobuf tooling (can be used for both linting and formatting)

### Linters

- **Buf** - Linter for Protocol Buffer files that catches common mistakes and enforces best practices

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "rules_proto", version = "6.0.0")
bazel_dep(name = "rules_buf", version = "0.5.2")
```

### 2. Configure Buf Toolchain

Add the Buf toolchain extension:

```starlark
buf = use_extension("@rules_buf//buf:extensions.bzl", "buf")

# see https://github.com/bufbuild/buf/releases
buf.toolchains(version = "v1.34.0")
use_repo(buf, "rules_buf_toolchains")
```

### 3. Configure Formatters and Linters

In `tools/format/BUILD.bazel`, set up the formatter:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

format_multirun(
    name = "format",
    protocol_buffer = "//tools/lint:buf",
    visibility = ["//:__subpackages__"],
)
```

In `tools/lint/linters.bzl`, set up the linter:

```starlark
load("@aspect_rules_lint//lint:buf.bzl", "lint_buf_aspect")
load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")

buf = lint_buf_aspect(
    config = Label("@//:buf.yaml"),
)

buf_test = lint_test(aspect = buf)
```

In `tools/lint/BUILD.bazel`, create an alias to the buf binary:

```starlark
alias(
    name = "buf",
    actual = "@rules_buf_toolchains//:buf",
)
```

### 4. Create Buf Configuration

Create a `buf.yaml` file in the root of your project:

```yaml
version: v2
lint:
  use:
    - DEFAULT
  except:
    - RPC_REQUEST_STANDARD_NAME
    - PACKAGE_DEFINED
```

### 5. Define Protobuf Targets

In your `BUILD.bazel` files, define protobuf targets:

```starlark
load("@rules_proto//proto:defs.bzl", "proto_library")

proto_library(
    name = "foo_proto",
    srcs = ["file.proto"],
    deps = [":unused"],
)
```

## Usage

### Format Code

Format all protobuf files:

```bash
bazel run //tools/format:format
```

Format specific files:

```bash
bazel run //tools/format:format -- file.proto
```

### Lint Code

Lint all protobuf files:

```bash
bazel run //tools/lint:lint
```

Lint specific targets:

```bash
bazel run //tools/lint:lint -- //src:foo_proto
```

### Run Linter Tests

```starlark
load("//tools/lint:linters.bzl", "buf_test")

buf_test(
    name = "buf",
    srcs = ["//src:foo_proto"],
)
```

Run the test:

```bash
bazel test //test:buf
```

## Example Code

See `src/` for example protobuf files:

- `file.proto` - A protobuf file with a service definition and intentional violations
- `unused.proto` - An unused protobuf file that demonstrates import checking

## Ignoring Lint Rules

You can ignore specific lint rules inline using comments:

```protobuf
// buf:lint:ignore RPC_RESPONSE_STANDARD_NAME
// buf:lint:ignore RPC_REQUEST_RESPONSE_UNIQUE
rpc ReceiveMessage(HttpBody) returns (Empty) {}
```
