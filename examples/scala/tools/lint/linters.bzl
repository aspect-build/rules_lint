"Define linter aspects for the Scala example"

load("@aspect_rules_lint//lint:scalafix.bzl", "lint_scalafix_aspect")

# Syntactic mode - runs DisableSyntax and other syntactic rules
scalafix = lint_scalafix_aspect(
    binary = Label("//tools/lint:scalafix"),
    config = Label("//:.scalafix.conf"),
)

# Semantic mode - runs OrganizeImports and other semantic rules
# Requires SemanticDB to be enabled in the scala_toolchain.
# To use semantic mode:
# 1. Configure your scala_toolchain with enable_semanticdb = True
# 2. Add OrganizeImports to your .scalafix.conf rules
#
# scalafix_semantic = lint_scalafix_aspect(
#     binary = Label("//tools/lint:scalafix"),
#     config = Label("//:.scalafix.conf"),
#     semantic = True,
# )
