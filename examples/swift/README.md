# Swift Formatting and Linting Example

This example demonstrates how to set up formatting and linting for Swift code using `rules_lint`.

## Supported Tools

### Formatters

- **SwiftFormat** - Code formatter for Swift

### Linters

- **SwiftLint** - Linter for Swift

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure Format Tools (add swiftformat)
4. Configure Lint Tools (add swiftlint)
5. Configure Formatters and Linters

- See `tools/format/BUILD` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up the linter aspect

6. Perform formatting and linting using `aspect format` and `aspect lint`

## SwiftLint Configuration

SwiftLint policy such as enabled rules, severity, and human reporter should
live in `.swiftlint.yml`. Bazel target membership determines which files the
aspect lints. SwiftLint `excluded` entries are still honored, but `included`
entries should not be used to narrow explicitly listed Bazel source files.

The aspect only needs the binary and config labels for a typical setup:

```starlark
swiftlint = lint_swiftlint_aspect(
    binary = Label("//tools/lint:swiftlint"),
    configs = [Label("//:.swiftlint.yml")],
)
```

For target-specific nested `.swiftlint.yml` files, declare the main config
first, then the nested configs, and set `config_mode = "nested"`:

```starlark
swiftlint = lint_swiftlint_aspect(
    binary = Label("//tools/lint:swiftlint"),
    configs = [
        Label("//:.swiftlint.yml"),
        Label("//src:nested/.swiftlint.yml"),
    ],
    config_mode = "nested",
)
```

rules_lint selects the deepest declared nested config that contains all Swift
sources in the target and passes only the main config plus that nearest nested
config to SwiftLint with `--config`. This mirrors [SwiftLint's default nested
configuration behavior](https://github.com/realm/SwiftLint#nested-configurations);
intermediate ancestor configs are not accumulated for deeper files. SwiftLint
does not auto-discover repository config files at execution time.

Declare SwiftLint config hierarchy files in `configs`; prefer the aspect's
`baseline` argument over a `baseline` entry in `.swiftlint.yml`:

```starlark
swiftlint_with_baseline = lint_swiftlint_aspect(
    binary = Label("//tools/lint:swiftlint"),
    configs = [Label("//:.swiftlint.yml")],
    baseline = Label("//:SwiftLintBaseline.json"),
)
```

## Example Code

See `src/formatme.swift` for a simple Swift file that SwiftFormat can format.
See `src/lintme.swift` for a separate Swift file with an intentional SwiftLint
violation. That lint fixture is marked `rules-lint-ignored` in `.gitattributes`
so formatting the example does not erase the lint demo.

## Configuration Files

- `.swiftlint.yml` - SwiftLint configuration for the example
- `src/nested/.swiftlint.yml` - nested SwiftLint configuration fixture
- `src/nested/deeper/.swiftlint.yml` - nearest nested configuration fixture
- `SwiftLintBaseline.json` - SwiftLint baseline used by the integration test
