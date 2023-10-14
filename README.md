# Run linters and formatters under Bazel

> It is currently EXPERIMENTAL and pre-release. No support is promised.
> There may be breaking changes, or we may archive and abandon the repository.

This ruleset integrates linting and formatting as first-class concepts under Bazel.

Features:

- **No changes needed to rulesets**. Works with the Bazel rules you already use.
- **No changes needed to BUILD files**. You don't need to add lint wrapper macros, and lint doesn't appear in `bazel query` output.
  Instead, users can lint their existing `*_library` targets.
- Lint results can be **presented in various ways**, see "Usage" below.
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

| Language                  | Formatter             | Linter(s)  |
| ------------------------- | --------------------- | ---------- |
| Python                    | [Black]               | [flake8]   |
| Java                      | [google-java-format]  | [pmd]      |
| Kotlin                    | [ktfmt]               |            |
| JavaScript/TypeScript/TSX | [Prettier]            | [ESLint]   |
| CSS/HTML                  | [Prettier]            |            |
| JSON                      | [Prettier]            |            |
| Markdown                  | [Prettier]            |            |
| Bash                      | [prettier-plugin-sh]  |            |
| SQL                       | [prettier-plugin-sql] |            |
| Starlark (Bazel)          | [Buildifier]          |            |
| Swift                     | [SwiftFormat] (1)     |            |
| Go                        | [gofmt]               |            |
| Protocol Buffers          | [buf]                 | [buf lint] |
| Terraform                 | [terraform] fmt       |            |
| Jsonnet                   | [jsonnetfmt]          |            |
| Scala                     | [scalafmt]            |            |

[prettier]: https://prettier.io
[google-java-format]: https://github.com/google/google-java-format
[black]: https://pypi.org/project/black/
[flake8]: https://flake8.pycqa.org/en/latest/index.html
[pmd]: https://docs.pmd-code.org/latest/index.html
[buf lint]: https://buf.build/docs/lint/overview
[eslint]: https://eslint.org/
[swiftformat]: https://github.com/nicklockwood/SwiftFormat
[terraform]: https://github.com/hashicorp/terraform
[buf]: https://docs.buf.build/format/usage
[ktfmt]: https://github.com/facebook/ktfmt
[buildifier]: https://github.com/keith/buildifier-prebuilt
[prettier-plugin-sh]: https://github.com/un-ts/prettier
[prettier-plugin-sql]: https://github.com/un-ts/prettier
[gofmt]: https://pkg.go.dev/cmd/gofmt
[jsonnetfmt]: https://github.com/google/go-jsonnet
[scalafmt]: https://scalameta.org/scalafmt

1. Non-hermetic: requires that a swift toolchain is installed on the machine.
   See https://github.com/bazelbuild/rules_swift#1-install-swift

To add a linter, please follow the steps in [lint/README.md](./lint/README.md) and then send us a PR.
Thanks!!

> We'll add documentation on adding formatters as well.

## Usage: Formatting

### One-time re-format all files

Assuming you installed with the typical layout:

`bazel run tools:format`

> Note that mass-reformatting can be disruptive in an active repo.
> You may want to instruct developers with in-flight changes to reformat their branches as well, to avoid merge conflicts.
> Also consider adding your re-format commit to the
> [`.git-blame-ignore-revs` file](https://docs.github.com/en/repositories/working-with-files/using-files/viewing-a-file#ignore-commits-in-the-blame-view)
> to avoid polluting the blame layer.

### Re-format specific file(s)

`bazel run tools:format some/file.md other/file.json`

### Install as a pre-commit hook

If you use [pre-commit.com](https://pre-commit.com/), add this in your `.pre-commit-config.yaml`:

```yaml
- repo: local
  hooks:
    - id: bazel-super-formatter
      name: Format
      language: system
      entry: bazel run //tools:format
      files: .*
```

> Note that pre-commit is silent while Bazel is fetching the tooling, which can make it appear hung on the first run.
> There is no way to avoid this; see https://github.com/pre-commit/pre-commit/issues/1003

If you don't use pre-commit, you can just wire directly into the git hook, however
this option will always run the formatter over all files, not just changed files.

```bash
$ echo "bazel run //tools:format" >> .git/hooks/pre-commit
$ chmod u+x .git/hooks/pre-commit
```

### Check that files are already formatted

This will exit non-zero if formatting is needed. You would typically run the check mode on CI.

`bazel run //tools:format -- --mode check`

## Usage: Linting

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

We haven't implemented this yet, follow https://github.com/aspect-build/rules_lint/issues/11

### 5. Code review comments

You can wire the reports from bazel-out to a tool like [reviewdog].

We're working on a demo with https://aspect.build/workflows that automatically runs `bazel lint` as
part of your CI and reports the results (including suggested fixes) to your GitHub Code Review thread.

## Installation

rules_lint currently only works with bzlmod under Bazel 6+.
This is because we accumulate dependencies which are difficult to express
in a WORKSPACE file.
We might add support for WORKSPACE in the future.

Follow instructions from the release you wish to use:
<https://github.com/aspect-build/rules_lint/releases>

### 1. Create tools/lint.bzl

Next, you must declare your linters as Bazel aspects.

> This is needed because Bazel only allows aspect attributes of type
> `bool`, `int` or `string`.
> We want to follow the documentation from
> https://bazel.build/extending/aspects#aspect_definition_2:
> Aspects are also allowed to have private attributes of types label or label_list. Private label attributes can be used to specify dependencies on tools or libraries that are needed for actions generated by aspects.

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
    properties:
      lint_aspects:
        - //tools:lint.bzl%eslint
        - //tools:lint.bzl%buf
```

If you don't use Aspect CLI, you can put these in some other wrapper like a shell script that runs the linter aspects over the requested targets.
See the `lint.sh` script in the `example/` folder.

### 2. Create tools/BUILD.bazel

Create a BUILD file that declares the formatter binary.
Each formatter should be installed in your repository, see our example/tools/BUILD file.

Then register them on the `formatters` attribute, for example:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "multi_formatter_binary")

# A target "black" is declared here

multi_formatter_binary(
    name = "format",
    formatters = {
        "Python": ":black",
    },
)
```

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
