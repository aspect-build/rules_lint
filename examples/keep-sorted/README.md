# Keep-Sorted Linting Example

This example demonstrates how to set up the [keep-sorted](https://github.com/google/keep-sorted) linter using `rules_lint`.

Keep-sorted is a tool that ensures code blocks marked with `// keep-sorted start` and `// keep-sorted end` comments are kept in sorted order.

## Supported Tools

### Linters

- **keep-sorted** - Ensures marked code blocks are kept in sorted order

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "rules_go", version = "0.52.0")
bazel_dep(name = "gazelle", version = "0.41.0")
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

### 3. Fetch keep-sorted Dependency

Add to MODULE.bazel to fetch the keep-sorted binary:

```starlark
keep_sorted_deps = use_extension("@gazelle//:extensions.bzl", "go_deps", isolate = True)
keep_sorted_deps.from_file(go_mod = "@aspect_rules_lint//lint/keep-sorted:go.mod")
use_repo(keep_sorted_deps, "com_github_google_keep_sorted")
```

**Important:** You must enable isolated extension usages in `.bazelrc`:

```
common --experimental_isolated_extension_usages
```

### 4. Configure Linter

In `tools/lint/linters.bzl`, set up the linter aspect:

```starlark
load("@aspect_rules_lint//lint:keep_sorted.bzl", "lint_keep_sorted_aspect")

keep_sorted = lint_keep_sorted_aspect(
    binary = Label("@com_github_google_keep_sorted//:keep-sorted"),
)
```

## Usage

### Mark Code Blocks for Sorting

Add `// keep-sorted start` and `// keep-sorted end` comments around code blocks you want to keep sorted:

```go
// keep-sorted start
import (
    "fmt"
    "os"
    "strings"
)
// keep-sorted end
```

### Lint Code

With Aspect CLI:

```bash
bazel lint //src:all
```

Without Aspect CLI:

```bash
./lint.sh src:all
```

### Fix Code

With Aspect CLI:

```bash
bazel lint --fix //src:all
```

## Example Code

See `src/example.go` for a simple example demonstrating keep-sorted markers.
