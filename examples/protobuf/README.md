# Protobuf Formatting and Linting Example

This example demonstrates how to set up formatting and linting for Protocol Buffer (protobuf) files using `rules_lint`.

## Supported Tools

### Formatters

- **Buf** - Modern protobuf tooling (can be used for both linting and formatting)

### Linters

- **Buf** - Linter for Protocol Buffer files that catches common mistakes and enforces best practices

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure Buf Toolchain
4. Configure Formatters and Linters

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up the linter aspect

4. Create `buf.yaml` configuration file
5. Perform formatting and linting using `aspect format` and `aspect lint`

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
