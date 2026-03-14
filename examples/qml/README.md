# QML Formatting and Linting Example

This example demonstrates how to set up formatting and linting for QML files using `rules_lint`.

## Supported Tools

### Formatters

- **qmlformat** - Qt's formatter for QML files

### Linters

- **qmllint** - Qt's linter for QML files

Both tools are invoked through the PySide wrappers `qmlformat` and `qmllint`.
The `qml` tag is used for both formatting and linting in this example.

## Setup

1. Configure `MODULE.bazel` with `rules_python` and `rules_lint`
2. Create the `MODULE.aspect` file to register CLI tasks
3. Install PySide tool wrappers with `pip.parse`
4. Configure formatters and linters

- See `tools/format/BUILD` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up the linter aspect

The linter example uses `.qmllint.ini` to promote `UnusedImports` from an informational diagnostic to a warning so the lint test fails on the sample file.

## Example Code

- `src/Main.qml` - QML file with formatting and lint violations

## Configuration Files

- `.qmlformat.ini` - qmlformat settings
- `.qmllint.ini` - qmllint warning settings
