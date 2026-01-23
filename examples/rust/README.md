# Rust Formatting and Linting Example

This example demonstrates how to set up formatting and linting for Rust code using `rules_lint`.

## Supported Tools

### Formatters

- **rustfmt** - Official Rust code formatter

### Linters

- **Clippy** - Rust linter that catches common mistakes and improves code quality

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure Rust Toolchain
4. Configure Formatters and Linters

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up the linter aspect

4. Create `.clippy.toml` configuration file (can be empty for defaults)
5. Perform formatting and linting using `aspect format` and `aspect lint`

## Example Code

See `src/` for example Rust files:

- `ok_binary.rs` - A simple Rust binary with no linting issues
- `ok_test.rs` - A simple Rust test with no linting issues
- `bad_binary.rs` - A Rust binary with intentional Clippy violations
- `bad_lib.rs` - A Rust library with intentional Clippy violations
- `bad_test.rs` - A Rust test with intentional Clippy violations
- `warning_lib.rs` - A Rust library with an intentional Clippy non-fatal warning
- `warning_and_error.rs` - A Rust library with an intentional Clippy warning and an intentional Clippy error

## Excluding Targets from Linting

You can exclude specific targets from Clippy linting by adding the `noclippy` tag:

```starlark
rust_binary(
    name = "excluded",
    srcs = ["excluded.rs"],
    edition = "2021",
    tags = ["noclippy"],
)
```
