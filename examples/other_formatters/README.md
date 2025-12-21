# Other Formatters Example

This example demonstrates formatting for various specialized languages and file formats that don't have dedicated examples.

## Supported Languages

### Formatters

- **CUE** - Configuration language (formatted with `cue fmt`)
- **Gherkin** - BDD testing language (formatted with Prettier + plugin)
- **GraphQL** - Query language (formatted with Prettier)
- **Jsonnet** - Data templating language (formatted with `jsonnetfmt`)
- **HTML Jinja** - Django/Jinja templates (formatted with `djlint`)
- **JSON5** - JSON with comments (formatted with Prettier)

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Configure Formatters

- See `tools/format/BUILD.bazel` for how to set up each formatter

4. Perform formatting using `aspect format`

## Example Code

The `src/` directory contains example files for each language:

- `hello.cue` - CUE configuration file
- `hello.feature` - Gherkin BDD test file
- `hello.graphql` - GraphQL query file
- `hello.jsonnet` - Jsonnet data template
- `hello.libsonnet` - Jsonnet library file
- `hello.html.jinja` - HTML Jinja template
- `config.json5` - JSON5 configuration file

## Configuration Files

- `prettier.config.cjs` - Prettier configuration with Gherkin plugin
- `package.json` - npm dependencies for Prettier and plugins
- `requirements.in` / `requirements.txt` - Python dependencies for djlint
