# Rust Formatting and Linting Example

This example demonstrates how to set up formatting and linting for Rust code using `rules_lint`.

## Supported Tools

### Formatters

- **rustfmt** - Official Rust code formatter

### Linters

- **Clippy** - Rust linter that catches common mistakes and improves code quality

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "rules_rust", version = "0.67.0")
```

### 2. Configure Rust Toolchain

Add the Rust toolchain extension:

```starlark
rust = use_extension("@rules_rust//rust:extensions.bzl", "rust")
rust.toolchain(
    edition = "2021",
    versions = ["1.75.0"],
)
use_repo(rust, "rust_toolchains")

register_toolchains(
    "@rust_toolchains//:all",
)
```

### 3. Configure Formatters and Linters

In `tools/format/BUILD.bazel`, set up the formatter:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

format_multirun(
    name = "format",
    rust = "@rules_rust//tools/upstream_wrapper:rustfmt",
    visibility = ["//:__subpackages__"],
)
```

In `tools/lint/linters.bzl`, set up the linter:

```starlark
load("@aspect_rules_lint//lint:clippy.bzl", "lint_clippy_aspect")
load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")

clippy = lint_clippy_aspect(
    config = Label("@//:.clippy.toml"),
)

clippy_test = lint_test(aspect = clippy)
```

### 4. Create Clippy Configuration

Create a `.clippy.toml` file in the root of your project (can be empty for defaults):

```toml
# Clippy configuration
# Add your clippy lints here
```

### 5. Define Rust Targets

In your `BUILD.bazel` files, define Rust targets:

```starlark
load("@rules_rust//rust:defs.bzl", "rust_binary", "rust_library")

rust_binary(
    name = "hello",
    srcs = ["hello.rs"],
    edition = "2021",
)
```

## Usage

### Format Code

Format all Rust files:

```bash
bazel run //tools/format:format
```

Format specific files:

```bash
bazel run //tools/format:format -- hello.rs
```

### Lint Code

Lint all Rust files:

```bash
bazel run //tools/lint:lint
```

Lint specific targets:

```bash
bazel run //tools/lint:lint -- //src:hello
```

### Run Linter Tests

```starlark
load("//tools/lint:linters.bzl", "clippy_test")

clippy_test(
    name = "clippy",
    srcs = ["//src:hello"],
)
```

Run the test:

```bash
bazel test //test:clippy
```

## Example Code

See `src/` for example Rust files:

- `ok_binary.rs` - A simple Rust binary with no linting issues
- `bad_binary.rs` - A Rust binary with intentional Clippy violations
- `bad_lib.rs` - A Rust library with intentional Clippy violations

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
