# Linting

## Installation

You must declare your linters as Bazel aspects.

> This is needed because Bazel only allows aspect attributes of type
> `bool`, `int` or `string`.
> We want to accept label-typed attributes, so we follow the documentation from
> https://bazel.build/extending/aspects#aspect_definition_2

We suggest creating a `lint.bzl` file in whatever package contains most of your
custom Bazel configuration, commonly in `tools/`.
This `lint.bzl` should contain linter aspect declarations.
See the `docs/` folder for "aspect factory functions" that declare your linters.

Finally, reference those linters as `//path/to:lint.bzl%mylinter`
in the lint runner.

If you use the Aspect CLI, then include a block like the following in `.aspect/cli/config.yaml`:

```yaml
plugins:
  - name: lint-plugin
    from: rules_lint
    properties:
      lint_aspects:
        - //tools:lint.bzl%eslint
```

If you don't use Aspect CLI, you can put these in some other wrapper like a shell script that runs the linter aspects over the requested targets.
See the `lint.sh` script in the `example/` folder.

## Usage

### 1. Warnings in the terminal with `bazel lint`

This ruleset provides an Aspect CLI plugin, so it can register the missing 'lint' command.

Users just type `bazel lint //path/to:targets`.

Reports are then written to the terminal.

[![asciicast](https://asciinema.org/a/xQWU1Wc1JINOubeguDDQbBqcq.svg)](https://asciinema.org/a/xQWU1Wc1JINOubeguDDQbBqcq)

### 2. Warnings in the terminal with a wrapper

You can use vanilla Bazel rather than Aspect CLI.

Placing a couple commands in a shell script, Makefile, or similar wrapper.

See the `example/lint.sh` file as an example.

[![asciicast](https://asciinema.org/a/gUUuQTCGIu85YMl6zz2GJIgD8.svg)](https://asciinema.org/a/gUUuQTCGIu85YMl6zz2GJIgD8)

### 3. Errors during `bazel build`

By adding `--aspects_parameters=fail_on_violation=true` to the command-line, we pass a parameter
to our linter aspects that cause them to honor the exit code of the lint tool.

This makes the build fail when any lint violations are present.

### 4. Failures during `bazel test`

Add a [make_lint_test](./lint_test.md) call to the `lint.bzl` file, then use the resulting rule in your BUILD files or in a wrapper macro.

### 5. Code review comments

You can wire the reports from bazel-out to a tool like [reviewdog].

We're working on a demo with https://aspect.build/workflows that automatically runs `bazel lint` as
part of your CI and reports the results (including suggested fixes) to your GitHub Code Review thread.
