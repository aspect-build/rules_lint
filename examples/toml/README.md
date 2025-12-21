# TOML Formatting Example

This example demonstrates how to set up formatting for TOML files using `rules_lint`.

## Supported Tools

### Formatters

- **Taplo** - TOML formatter

Note: No TOML linter is currently available in rules_lint.

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "bazel_features", version = "1.32.0")
```

### 2. Configure Format Tools

Add taplo to your format tools:

```starlark
format_tools = use_extension("@aspect_rules_lint//format:extensions.bzl", "tools")
format_tools.taplo()
use_repo(format_tools, "taplo")
```

### 3. Configure Formatter

In `tools/format/BUILD.bazel`, set up the formatter:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")
load("@bazel_lib//lib:expand_template.bzl", "expand_template")

genrule(
    name = "taplo",
    srcs = ["@taplo//file"],
    outs = ["taplo_bin"],
    cmd = "gunzip -c $< > $@",
    executable = True,
)

expand_template(
    name = "taplo_wrapper",
    out = "taplo_wrapper.sh",
    data = [":taplo_bin"],
    is_executable = True,
    substitutions = {"{taplo_bin}": "$(execpath :taplo_bin)"},
    template = [
        "#!/bin/sh",
        'exec env RUST_LOG=warn "./{taplo_bin}" "$@"',
    ],
)

format_multirun(
    name = "format",
    toml = ":taplo_wrapper",
    visibility = ["//:__subpackages__"],
)
```

## Usage

### Format Code

Format all TOML files:

```bash
bazel run //tools/format:format
```

Format specific files:

```bash
bazel run //tools/format:format -- hello.toml
```

## Example Code

See `src/hello.toml` for a simple example TOML file.
