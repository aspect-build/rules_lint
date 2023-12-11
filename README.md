# Run linters and formatters under Bazel

This ruleset integrates linting and formatting as first-class concepts under Bazel.

Features:

- **No changes needed to rulesets**. Works with the Bazel rules you already use.
- **No changes needed to BUILD files**. You don't need to add lint wrapper macros, and lint doesn't appear in `bazel query` output.
  Instead, users can lint their existing `*_library` targets.
- Lint results can be **presented in various ways**, see [Usage](https://github.com/aspect-build/rules_lint/blob/main/docs/linting.md#usage) below.
- **Can format files not known to Bazel**. Formatting just runs directly on the file tree.
  No need to create `sh_library` targets for your shell scripts, for example.
- Honors the same configuration files you use for these tools outside Bazel (e.g. in the editor)

This project is inspired by the design for [Tricorder].
This is how Googlers get their static analysis results in code review (Critique).
https://github.com/google/shipshape is an old, abandoned attempt to open-source Tricorder.
It is also inspired by <https://github.com/github/super-linter>.

[aspect cli]: https://docs.aspect.build/v/cli
[tricorder]: https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/43322.pdf
[reviewdog]: https://github.com/reviewdog/reviewdog

## Design

Formatting and Linting work a bit differently.

| Formatter                                                         | Linter                                                 |
| ----------------------------------------------------------------- | ------------------------------------------------------ |
| Only one per language, since they could conflict with each other. | Many per language is fine; results compose.            |
| Invariant: program's behavior is never changed.                   | Suggested fixes may change behavior.                   |
| Developer has no choices. Always blindly accept result.           | Fix may be manual, or select from multiple auto-fixes. |
| Changes must be applied.                                          | Violations can be suppressed.                          |
| Operates on a single file at a time.                              | Can require the dependency graph.                      |
| Can always format just changed files / regions                    | New violations might be introduced in unchanged files. |
| Fast enough to put in a pre-commit workflow.                      | Some are slow.                                         |

This leads to some minor differences in how they are used in rules_lint.

## Available tools

| Language                  | Formatter             | Linter(s)                |
| ------------------------- | --------------------- | ------------------------ |
| Python                    | [ruff]                | [flake8], [ruff], [mypy] |
| Java                      | [google-java-format]  | [pmd]                    |
| Kotlin                    | [ktfmt]               |                          |
| JavaScript/TypeScript/TSX | [Prettier]            | [ESLint]                 |
| CSS/HTML                  | [Prettier]            |                          |
| JSON                      | [Prettier]            |                          |
| Markdown                  | [Prettier]            |                          |
| Bash                      | [shfmt]               | [shellcheck]             |
| SQL                       | [prettier-plugin-sql] |                          |
| Starlark (Bazel)          | [Buildifier]          |                          |
| Swift                     | [SwiftFormat] (1)     |                          |
| Go                        | [gofmt]               |                          |
| Protocol Buffers          | [buf]                 | [buf lint]               |
| Terraform                 | [terraform] fmt       |                          |
| Jsonnet                   | [jsonnetfmt]          |                          |
| Scala                     | [scalafmt]            |                          |

[prettier]: https://prettier.io
[google-java-format]: https://github.com/google/google-java-format
[flake8]: https://flake8.pycqa.org/en/latest/index.html
[pmd]: https://docs.pmd-code.org/latest/index.html
[buf lint]: https://buf.build/docs/lint/overview
[eslint]: https://eslint.org/
[swiftformat]: https://github.com/nicklockwood/SwiftFormat
[terraform]: https://github.com/hashicorp/terraform
[buf]: https://docs.buf.build/format/usage
[ktfmt]: https://github.com/facebook/ktfmt
[buildifier]: https://github.com/keith/buildifier-prebuilt
[prettier-plugin-sql]: https://github.com/un-ts/prettier
[gofmt]: https://pkg.go.dev/cmd/gofmt
[jsonnetfmt]: https://github.com/google/go-jsonnet
[scalafmt]: https://scalameta.org/scalafmt
[ruff]: https://docs.astral.sh/ruff/
[shellcheck]: https://www.shellcheck.net/
[shfmt]: https://github.com/mvdan/sh
[mypy]: https://mypy.readthedocs.io/en/stable/index.html

1. Non-hermetic: requires that a swift toolchain is installed on the machine.
   See https://github.com/bazelbuild/rules_swift#1-install-swift

To add a linter, please follow the steps in [lint/README.md](./lint/README.md) and then send us a PR.
Thanks!!

> We'll add documentation on adding formatters as well.

## Installation

Follow instructions from the release you wish to use:
<https://github.com/aspect-build/rules_lint/releases>

## Usage

### Format

To format files, run the target you create when you install rules_lint.

We recommend using a Git pre-commit hook to format changed files, by running `bazel run //:format [changed file ...]`.

[![asciicast](https://asciinema.org/a/vGTpzD0obvhILEcSxYAVrlpqT.svg)](https://asciinema.org/a/vGTpzD0obvhILEcSxYAVrlpqT)

See [Formatting](./docs/formatting.md) for more ways to use the formatter, such as a pre-commit hook or a CI check.

### Lint

To lint code, we recommend using the Aspect CLI to get the missing `lint` command.

For example, running `bazel lint //src:all` prints lint warnings to the terminal for all targets in the `//src` package:

[![asciicast](https://asciinema.org/a/xQWU1Wc1JINOubeguDDQbBqcq.svg)](https://asciinema.org/a/xQWU1Wc1JINOubeguDDQbBqcq)

See [Linting](./docs/linting.md) for more ways to use the linter, such as running as a test target, or presenting results as code review comments.

### Ignoring files

The linters only visit files that are part of the Bazel dependency graph (listed as `srcs` to some library target).

The formatter honors the `.gitignore` file.
Otherwise use the affordance provided by the tool, for example `.prettierignore` for files to be ignored by Prettier.

Sometimes engineers want to ignore a file with a certain extension because the content isn't actually valid syntax for the corresponding language.
For example, you might write a template for YAML and name it `my-template.yaml` even though it needs to have some interpolated values inserted before it's syntactically valid.
We recommend instead fixing the file extension. In this example, `my.yaml.tmpl` or `my-template.yaml_` might be better.

### Using with your editor

We believe that existing editor plugins should just work as-is. They may download or bundle their own
copy of the tools, which can lead to some version skew in lint/format rules.

For formatting, we believe it's a waste of time to configure these in the editor, because developers
should just rely on formatting happening when they commit and not care what the code looks like before that point.
But we're not trying to stop anyone, either!

You could probably configure the editor to always run the same Bazel command, any time a file is changed.
Instructions to do this are out-of-scope for this repo, particularly since they have to be formulated and updated for so many editors.

### Using a formatter from a BUILD rule

Generally, you should just allow code generators to make messy files.
You can exclude them from formatting by changing the file extension,
adding a suppression comment at the top (following the formatter's docs)
or adding to the formatter's ignore file (e.g. `.prettierignore`).

However there are some valid cases where you really want to run a formatter as a build step.
You can just reach into the external repository where we've installed them.

For example, to run Prettier:

```starlark
load("@aspect_rules_format_npm//:prettier/package_json.bzl", prettier = "bin")

prettier.prettier_binary(name = "prettier")

js_run_binary(
    name = "fmt",
    srcs = ["raw_file.md"],
    args = ["raw_file.md"],
    chdir = package_name(),
    stdout = "formatted_file.md",
    tool = "prettier",
)
```
