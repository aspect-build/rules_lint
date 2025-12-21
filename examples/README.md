# Examples

This directory contains language-specific examples demonstrating how to use `rules_lint` for both formatting and linting.

Each example is self-contained and shows:

- How to set up formatting and linting for a specific language
- Minimal working configuration
- How to run formatters and linters with Bazel

## Structure

- `python/` - Python formatting with Ruff; linting with Ruff, Flake8, or Pylint
- `typescript/` - TypeScript/JavaScript formatting with Prettier; linting with ESLint
- `java/` - Java formatting with Google Java Format; linting with PMD, Checkstyle, or SpotBugs
- `rust/` - Rust formatting with rustfmt; linting with Clippy
- `cpp/` - C/C++ formatting with clang-format; linting with Clang-Tidy or Cppcheck
- `shell/` - Shell script formatting with shfmt; linting with ShellCheck
- `ruby/` - Ruby formatting with RuboCop; linting with RuboCop or StandardRB
- `kotlin/` - Kotlin formatting with ktfmt; linting with Ktlint
- `css/` - CSS formatting with Prettier; linting with Stylelint
- `yaml/` - YAML formatting with yamlfmt; linting with Yamllint
- `markdown/` - Markdown formatting with Prettier; linting with Vale
- `proto/` - Protocol Buffer formatting and linting with Buf

## Multi-language Example

For examples of a monorepo with multiple languages, see the `example/` directory at the repository root.
