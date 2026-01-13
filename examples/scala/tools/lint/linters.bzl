"Define linter aspects for the Scala example"

load("@aspect_rules_lint//lint:scalafix.bzl", "lint_scalafix_aspect")

# Syntactic mode - runs DisableSyntax and other syntactic rules
scalafix = lint_scalafix_aspect(
    binary = Label("//tools/lint:scalafix"),
    config = Label("//:.scalafix.conf"),
)

# Semantic mode - runs OrganizeImports and other semantic rules
# Requires SemanticDB to be enabled in the scala_toolchain.
# See //tools/scala:semanticdb_toolchain for the toolchain configuration.
scalafix_semantic = lint_scalafix_aspect(
    binary = Label("//tools/lint:scalafix"),
    config = Label("//:.scalafix.semantic.conf"),
    semantic = True,
)
