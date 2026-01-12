"Define linter aspects for the Scala example"

load("@aspect_rules_lint//lint:scalafix.bzl", "lint_scalafix_aspect")

scalafix = lint_scalafix_aspect(
    binary = Label("//tools/lint:scalafix"),
    config = Label("//:.scalafix.conf"),
)

# For semantic mode (requires SemanticDB in scala_toolchain):
# scalafix_semantic = lint_scalafix_aspect(
#     binary = Label("//tools/lint:scalafix"),
#     config = Label("//:.scalafix.conf"),
#     semantic = True,
# )
