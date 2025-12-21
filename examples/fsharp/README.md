# F# Formatting Example

This example demonstrates how to set up formatting for F# code using `rules_lint`.

## Supported Tools

### Formatters

- **Fantomas** - F# source code formatter

Note: No F# linter is currently available in rules_lint.

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "rules_dotnet", version = "0.20.5")
```

### 2. Configure .NET Toolchain

Add the .NET toolchain extension:

```starlark
dotnet = use_extension("@rules_dotnet//dotnet:extensions.bzl", "dotnet")
dotnet.toolchain(dotnet_version = "9.0.306")
use_repo(dotnet, "dotnet_toolchains")

register_toolchains("@dotnet_toolchains//:all")
```

### 3. Configure Paket Dependencies

Set up Paket for NuGet package management. See `3rdparty/nuget/` for paket dependency setup.

The `paket.main.bzl` file should include Fantomas:

```starlark
nuget_repo(
    name = "paket.main",
    packages = [
        {"name": "fantomas", "id": "fantomas", "version": "7.0.3", ...},
        {"name": "Paket", "id": "Paket", "version": "9.0.2", ...},
    ],
)
```

### 4. Configure Formatter

In `tools/format/BUILD.bazel`, set up the formatter:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

format_multirun(
    name = "format",
    fsharp = "@paket.main//fantomas/tools:fantomas",
    visibility = ["//:__subpackages__"],
)
```

### 5. Define F# Targets

In your `BUILD.bazel` files, define F# targets:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "fsharp_binary")

fsharp_binary(
    name = "hello",
    srcs = ["hello.fs"],
    target_frameworks = ["net9.0"],
)
```

## Usage

### Format Code

Format all F# files:

```bash
bazel run //tools/format:format
```

Format specific files:

```bash
bazel run //tools/format:format -- hello.fs
```

## Example Code

See `src/hello.fs` for a simple example F# program.
