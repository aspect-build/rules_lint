# Linting

## Installation

You must declare your linters as Bazel aspects.

> This is needed because Bazel only allows aspect attributes of type
> `bool`, `int` or `string`.
> We want to accept label-typed attributes, so we follow the documentation from
> https://bazel.build/extending/aspects#aspect_definition_2

We suggest creating a `linters.bzl` file in whatever package contains most of your
custom Bazel configuration, commonly in `tools/lint`.
This `linters.bzl` should contain linter aspect declarations.

See the [example linters.bzl](/example/tools/lint/linters.bzl) for a complete install example.
See the `docs/` folder for API docs of the "aspect factory functions" that declare your linters.
Some linter tools are built-in to rules_lint and may be installed by [multitool].
The aspect factory function docs in the `docs/` folder describe when these are available and how to use them.

Finally, register those linter aspects in the lint runner. See details below.

[multitool]: https://registry.bazel.build/modules/rules_multitool

## Usage

### 1. Linter as Code Review Bot

[Aspect Workflows] includes a `lint` task, which wires the reports from `bazel-out` directly into your code review.
The fixes produced by the tool are shown as suggested edits, so you can just accept without a context-switch back to your development machine.

![lint suggestions in code review](./lint_workflow.png)

We recommend this workflow for several reasons:

1. Forcing engineers to fix lint violations on code they're still iterating is a waste of time.
   Code review is the right time to consider whether the code changes meet your team's quality bar.
2. Code review has at least two parties, which means that comments aren't simply ignored.
   The reviewer has to agree with the author whether a suggested lint violation should be corrected.
   Compare this with the usual complaint "developers just ignore warnings" - that's because the warnings were presented in their local build.
3. Adding a new linter (or adjusting its configuration to be stricter) doesn't require that you fix or suppress all existing warnings in the repository.
   This makes it more feasible for an enthusiastic volunteer to setup a linter, without having the burden of "making it green" on all existing code.
4. Linters shouldn't be required to have zero false-positives. Some lint checks are quite valuable when they detect a problem, but cannot always avoid overdetection.
   Since code review comments are always subject to human review, it's the right time to evaluate the suggestions and ignore those which don't make sense.
5. This is how Google does it, in the [Tricorder] tool that's integrated into code review (Critique) to present static analysis results.
   With [Aspect Workflows] we've provided a similar experience.

[Tricorder]: https://static.googleusercontent.com/media/research.google.com/en/pubs/archive/43322.pdf

### 2. Warnings in the terminal with `bazel lint`

[Aspect CLI] adds the missing 'lint' command, so users just type `bazel lint //path/to:targets`.

- Lint reports are written to the terminal.
- If a linter reports errors (by exiting non-zero), then `lint` exits 1.
- If suggested fixes are produced by linters, `lint` will offer to apply them.

To configure it, add a block like the following in `.aspect/cli/config.yaml` to point to the `*_lint` definition symbols.
The `%` syntax is the same as [aspects declared on the command-line](https://bazel.build/extending/aspects#invoking_the_aspect_using_the_command_line)

```yaml
lint:
  aspects:
    # Format: <extension file label>%<aspect top-level name>
    - //tools/lint:linters.bzl%eslint
```

[![asciicast](https://asciinema.org/a/xQWU1Wc1JINOubeguDDQbBqcq.svg)](https://asciinema.org/a/xQWU1Wc1JINOubeguDDQbBqcq)

### 3. Warnings in the terminal with a wrapper

If you don't use [Aspect CLI], you can use vanilla Bazel with some wrapper like a shell script that runs the linter aspects over the requested targets.

See the [example/lint.sh](/example/lint.sh) file as an example, and pay attention to the comments at the top about fitting it into your repo.

[![asciicast](https://asciinema.org/a/gUUuQTCGIu85YMl6zz2GJIgD8.svg)](https://asciinema.org/a/gUUuQTCGIu85YMl6zz2GJIgD8)

Note that you can also pass `--fix` to apply fixes from linters that provide them.
This is the same flag many linters support.

[![asciicast](https://asciinema.org/a/r9JKJ8uKgAZTzlUPdDdHlY1CB.svg)](https://asciinema.org/a/r9JKJ8uKgAZTzlUPdDdHlY1CB)

### 4. Errors during `bazel build`

Add at least the following to the command-line or to your `.bazelrc` file to cause all linter aspects to honor the exit code of the lint tool:

```
--aspects=//tools/lint:linters.bzl%eslint  # replace with your linter
--@aspect_rules_lint//lint:fail_on_violation
```

This makes the build fail when any lint violations are present.
You may wish to use the `--keep_going` flag to continue linting even after the first failure. See [example/lint.sh](/example/lint.sh) for more available flags.

### 5. Failures during `bazel test`

Call the [lint_test](./lint_test.md) factory function in your `linters.bzl` file, then use the resulting rule in your BUILD files or in a wrapper macro.

See the `example/test/BUILD.bazel` file in this repo for some examples.

## Configuring linters

rules_lint doesn't provide any new way to configure linter tools.
Instead you simply use the same configuration files the documentation for the linter suggests.
Each linter aspect accepts the configuration file(s) as an argument.

To specify whether a certain lint rule should be a warning or error, follow the documentation for the linter.
rules_lint provides the exit code of the linter process to allow the desired developer experiences listed above.

### Terraform linting

Terraform modules can be linted with `lint_tflint_aspect`, which relies on the toolchains published by
[`rules_tf`](https://github.com/yanndegat/rules_tf). Add that module (or the equivalent WORKSPACE repositories)
and register the toolchains so the aspect can locate both Terraform and TFLint binaries:

```starlark
bazel_dep(name = "rules_tf", version = "0.0.10")

tf = use_extension("@rules_tf//tf:extensions.bzl", "tf_repositories")
tf.download(
    version = "1.9.8",
    mirror = {"aws": "hashicorp/aws:5.90.0"},
)
use_repo(tf, "tf_toolchains")
register_toolchains("@tf_toolchains//:all")
```

Then declare the aspect alongside your other linters:

```starlark
load("@aspect_rules_lint//lint:tflint.bzl", "lint_tflint_aspect")

tflint = lint_tflint_aspect()
```

In WORKSPACE projects, fetch `rules_tf` via `rules_lint_dependencies()` and register matching
toolchains using the helper exposed by rules_lint:

```starlark
load("@aspect_rules_lint//lint:tf_toolchains_workspace.bzl", "rules_lint_setup_tf_toolchains")

rules_lint_setup_tf_toolchains(
    version = "1.9.8",
    mirror = {"aws": "hashicorp/aws:5.90.0"},
)
```

The helper detects the host platform automatically using Bazel's host platform constraints.

## Ignoring targets

To ignore a specific target, you can use the `no-lint` tag. This will prevent the linter from visiting the target.

## Linting generated files

By default, we filter out generated files from linting.

To bypass this filter, add `tags=["lint-genfiles"]` to a target to force all the `srcs` to be linted.

## Debugging

Some linters honor the debug flag in this repo. To enable it, add a Bazel flag:
`--@aspect_rules_lint//lint:debug`

[Aspect Workflows]: https://docs.aspect.build/workflows
[Aspect CLI]: https://docs.aspect.build/cli
