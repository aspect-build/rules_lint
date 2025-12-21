# XML Formatting Example

This example demonstrates how to set up formatting for XML files using `rules_lint`.

## Supported Tools

### Formatters

- **Prettier** - XML formatter (via Prettier XML plugin)

Note: No XML linter is currently available in rules_lint.

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "aspect_rules_js", version = "2.0.0")
bazel_dep(name = "bazel_features", version = "1.29.0")
```

### 2. Set up npm dependencies

Install npm dependencies and generate the lock file:

```bash
pnpm install
```

This will create `pnpm-lock.yaml` based on `package.json`.

### 3. Configure Prettier

Set up Prettier with XML plugin support. See `tools/format/BUILD.bazel` for configuration.

### 3. Configure Formatter

In `tools/format/BUILD.bazel`, set up the formatter:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")
load("@npm//:prettier/package_json.bzl", prettier = "bin")

prettier.prettier_binary(
    name = "prettier",
    data = ["//:prettierrc"],
    env = {"BAZEL_BINDIR": "."},
    fixed_args = [
        "--config=\"$$JS_BINARY__RUNFILES\"/$(rlocationpath //:prettierrc)",
        "--loglevel=warn",
    ],
)

format_multirun(
    name = "format",
    xml = ":prettier",
    visibility = ["//:__subpackages__"],
)
```

## Usage

### Format Code

Format all XML files:

```bash
bazel run //tools/format:format
```

Format specific files:

```bash
bazel run //tools/format:format -- hello.xml
```

## Example Code

See `src/hello.xml` for a simple example XML file.
