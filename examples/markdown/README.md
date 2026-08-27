# Markdown Linting Example

This example uses rumdl to lint Markdown and validate repository-local links.

Markdown files are exposed to the aspect through a `filegroup` tagged `markdown`.
Linked files needed by MD051 and MD057 are declared through the aspect's `data`
attribute so they are available in Bazel's sandbox.
