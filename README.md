# Run linters and formatters under Bazel

This ruleset integrates linting and formatting as first-class concepts under Bazel.

Features:

- **No changes needed to rulesets**. Works with the Bazel rules you already use.
- **No changes needed to BUILD files**. You don't need to add lint wrapper macros, and lint doesn't appear in `bazel query` output.
  Instead, users simply lint their existing `*_library` targets.
- **Incremental**. Lint checks (including producing fixes) are run as normal Bazel actions, which means they support Remote Execution and the outputs are stored in the Remote Cache.
- Lint results can be **presented in various ways**, such as Code Review comments or failing tests.
  See [Usage](https://github.com/aspect-build/rules_lint/blob/main/docs/linting.md#usage).
- **Can lint changes only**. It's fine if your repository has a lot of existing issues.
  It's not necessary to fix or suppress all of them to start linting new changes.
  This is sometimes called the "Water Leak Principle": you should always fix a leak before mopping the spill.
- **Can format files not known to Bazel**. Formatting just runs directly on the file tree.
  No need to create `sh_library` targets for your shell scripts, for example.
- Honors the same **configuration files** you use for these tools outside Bazel (e.g. in the editor)

**Watch Alex's talk at BazelCon 2024:**

[![rules_lint at BazelCon](https://img.youtube.com/vi/CnK-RAdfrpI/0.jpg)](https://www.youtube.com/watch?v=CnK-RAdfrpI)

## Supported tools

New tools are being added frequently, so check this page again!

Linters which are not language-specific:

- [keep-sorted]

| Language               | Formatter                 | Linter(s)                        |
| ---------------------- | ------------------------- | -------------------------------- |
| C / C++                | [clang-format]            | [clang-tidy]                     |
| Cuda                   | [clang-format]            |                                  |
| CSS, Less, Sass        | [Prettier]                | [Stylelint]                      |
| Go                     | [gofmt] or [gofumpt]      |                                  |
| Gherkin                | [prettier-plugin-gherkin] |                                  |
| GraphQL                | [Prettier]                |                                  |
| HCL (Hashicorp Config) | [terraform] fmt           |                                  |
| HTML                   | [Prettier]                |                                  |
| JSON                   | [Prettier]                |                                  |
| Java                   | [google-java-format]      | [pmd] , [Checkstyle], [Spotbugs] |
| JavaScript             | [Prettier]                | [ESLint]                         |
| HTML templates         | [djlint]                  |                                  |
| Jsonnet                | [jsonnetfmt]              |                                  |
| Kotlin                 | [ktfmt]                   | [ktlint]                         |
| Markdown               | [Prettier]                | [Vale]                           |
| Protocol Buffer        | [buf]                     | [buf lint]                       |
| Python                 | [ruff]                    | [flake8], [pylint], [ruff]       |
| Rust                   | [rustfmt]                 |                                  |
| SQL                    | [prettier-plugin-sql]     |                                  |
| Scala                  | [scalafmt]                |                                  |
| Shell                  | [shfmt]                   | [shellcheck]                     |
| Starlark               | [Buildifier]              |                                  |
| Swift                  | [SwiftFormat] (1)         |                                  |
| TOML                   | [taplo]                   |                                  |
| TSX                    | [Prettier]                | [ESLint]                         |
| TypeScript             | [Prettier]                | [ESLint]                         |
| YAML                   | [yamlfmt]                 | [yamllint]                        |
| XML                    | [prettier/plugin-xml]     |                                  |

[prettier]: https://prettier.io
[google-java-format]: https://github.com/google/google-java-format
[flake8]: https://flake8.pycqa.org/en/latest/index.html
[pmd]: https://docs.pmd-code.org/latest/index.html
[checkstyle]: https://checkstyle.sourceforge.io/cmdline.html
[spotbugs]: https://spotbugs.github.io/
[buf lint]: https://buf.build/docs/lint/overview
[eslint]: https://eslint.org/
[swiftformat]: https://github.com/nicklockwood/SwiftFormat
[terraform]: https://github.com/hashicorp/terraform
[buf]: https://docs.buf.build/format/usage
[keep-sorted]: https://github.com/google/keep-sorted
[ktfmt]: https://github.com/facebook/ktfmt
[ktlint]: https://github.com/pinterest/ktlint
[buildifier]: https://github.com/keith/buildifier-prebuilt
[djlint]: https://djlint.com/
[prettier-plugin-sql]: https://github.com/un-ts/prettier
[prettier-plugin-gherkin]: https://github.com/mapado/prettier-plugin-gherkin
[prettier/plugin-xml]: https://github.com/prettier/plugin-xml
[gofmt]: https://pkg.go.dev/cmd/gofmt
[gofumpt]: https://github.com/mvdan/gofumpt
[jsonnetfmt]: https://github.com/google/go-jsonnet
[scalafmt]: https://scalameta.org/scalafmt
[ruff]: https://docs.astral.sh/ruff/
[pylint]: https://pylint.readthedocs.io/en/stable/
[shellcheck]: https://www.shellcheck.net/
[shfmt]: https://github.com/mvdan/sh
[taplo]: https://taplo.tamasfe.dev/
[clang-format]: https://clang.llvm.org/docs/ClangFormat.html
[clang-tidy]: https://clang.llvm.org/extra/clang-tidy/
[vale]: https://vale.sh/
[yamlfmt]: https://github.com/google/yamlfmt
[yamllint]: https://yamllint.readthedocs.io/en/stable/
[rustfmt]: https://rust-lang.github.io/rustfmt
[stylelint]: https://stylelint.io

1. Non-hermetic: requires that a swift toolchain is installed on the machine.
   See https://github.com/bazelbuild/rules_swift#1-install-swift

To add a tool, please follow the steps in [lint/README.md](./lint/README.md) or [format/README.md](./format/README.md)
and then send us a PR.
Thanks!!

## Installation

Follow instructions from the release you wish to use:
<https://github.com/aspect-build/rules_lint/releases>

## Usage

Formatting and Linting are inherently different, which leads to differences in how they are used in rules_lint.

| Formatter                                                         | Linter                                                 |
| ----------------------------------------------------------------- | ------------------------------------------------------ |
| Only one per language, since they could conflict with each other. | Many per language is fine; results compose.            |
| Invariant: program's behavior is never changed.                   | Suggested fixes may change behavior.                   |
| Developer has no choices. Always blindly accept result.           | Fix may be manual, or select from multiple auto-fixes. |
| Changes must be applied.                                          | Violations can be suppressed.                          |
| Operates on a single file at a time.                              | Can require the dependency graph.                      |
| Can always format just changed files / regions                    | New violations might be introduced in unchanged files. |
| Fast enough to put in a pre-commit workflow.                      | Some are slow.                                         |

### Format

To format files, run the target you create when you install rules_lint.

We recommend using a Git pre-commit hook to format changed files, and [Aspect Workflows] to provide the check on CI.

See [Formatting](./docs/formatting.md) for more ways to use the formatter.

Demo:
![pre-commit format](./docs/format-demo.svg)

### Lint

To lint code, we recommend using the [Aspect CLI] to get the missing `lint` command, and [Aspect Workflows] to provide first-class support for "linters as code reviewers".

For example, running `bazel lint //src:all` prints lint warnings to the terminal for all targets in the `//src` package.
Suggested fixes from the linter tools are presented interactively.

See [Linting](./docs/linting.md) for more ways to use the linter.

Demo:
![bazel lint demo](./docs/lint-fix-demo.svg)

### Ignoring files

The linters only visit files that are part of the Bazel dependency graph (listed as `srcs` to some library target).

The formatter honors the `.gitignore` and `.gitattributes` files.
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

## FAQ

### What about type-checking?

We consider type-checkers as a build tool, not as a linter. This is for a few reasons:

- They are commonly distributed along with compilers.
  In compiled languages like Java, types are required in order for the compiler to emit executable bytecode at all.
  In interpreted languages they're still often linked, e.g. TypeScript does both "compiling" to JavaScript and also type-checking.
  This suggests that rules for a language should include the type-checker,
  e.g. we expect Sorbet to be integrated with rules_ruby and mypy/pyright to be integrated with rules_python or Aspect's rules_py.
- We think most developers want "build error" semantics for type-checks:
  the whole repository should successfully type-check or you cannot commit the change.
  rules_lint is optimized for "warning" semantics, where we produce report files and it's up to the
  Dev Infra team how to present those, for example only on changed files.
- You can only type-check a library if its dependencies were checkable, which means short-circuiting
  execution. rules_lint currently runs linters on every node in the dependency graph, including any
  whose dependencies have lint warnings.

Rulesets for type-checkers:

- Python: [rules_mypy](https://github.com/theoremlp/rules_mypy)

[aspect workflows]: https://docs.aspect.build/workflows
[aspect cli]: https://docs.aspect.build/cli

# Telemetry & privacy policy

This ruleset collects limited usage data via [`tools_telemetry`](https://github.com/aspect-build/tools_telemetry), which is reported to Aspect Build Inc and governed by our [privacy policy](https://www.aspect.build/privacy-policy).
