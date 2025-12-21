# Shell Formatting and Linting Example

This example demonstrates how to set up formatting and linting for shell scripts using `rules_lint`.

## Supported Tools

### Formatters

- **shfmt** - Shell formatter that formats shell programs

### Linters

- **ShellCheck** - Static analysis tool for shell scripts

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "rules_shell", version = "0.5.0")
```

### 2. Configure Formatters and Linters

In `tools/format/BUILD.bazel`, set up the formatter:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

format_multirun(
    name = "format",
    shell = "@aspect_rules_lint//format:shfmt",
    visibility = ["//:__subpackages__"],
)
```

In `tools/lint/linters.bzl`, set up the linter:

```starlark
load("@aspect_rules_lint//lint:shellcheck.bzl", "lint_shellcheck_aspect")
load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")

shellcheck = lint_shellcheck_aspect(
    binary = Label("@aspect_rules_lint//lint:shellcheck_bin"),
    config = Label("@//:.shellcheckrc"),
)

shellcheck_test = lint_test(aspect = shellcheck)
```

### 3. Create ShellCheck Configuration

Create a `.shellcheckrc` file in the root of your project:

```bash
# Turn on warnings for unquoted variables with safe values
enable=quote-safe-variables

# Turn on warnings for unassigned uppercase variables
enable=check-unassigned-uppercase

# Allow [ ! -z foo ] instead of suggesting -n
disable=SC2236
```

### 4. Define Shell Targets

In your `BUILD.bazel` files, define shell targets:

```starlark
load("@rules_shell//shell:sh_library.bzl", "sh_library")

sh_library(
    name = "hello",
    srcs = ["hello.sh"],
)
```

## Usage

### Format Code

Format all shell files:

```bash
bazel run //tools/format:format
```

Format specific files:

```bash
bazel run //tools/format:format -- hello.sh
```

### Lint Code

Lint all shell files:

```bash
bazel run //tools/lint:lint
```

Lint specific targets:

```bash
bazel run //tools/lint:lint -- //src:hello
```

### Verify Formatting

Add a `format_test` to ensure files are formatted:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_test")

format_test(
    name = "format_files_test",
    srcs = ["hello.sh"],
)
```

Run the test:

```bash
bazel test //src:format_files_test
```

### Run Linter Tests

```starlark
load("//tools/lint:linters.bzl", "shellcheck_test")

shellcheck_test(
    name = "shellcheck",
    srcs = ["//src:hello"],
)
```

Run the test:

```bash
bazel test //test:shellcheck
```

## Example Code

See `src/hello.sh` for a simple example shell script with intentional violations to demonstrate linting.
