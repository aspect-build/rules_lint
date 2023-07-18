"Define linter aspects"

load("@aspect_rules_lint//lint:buf.bzl", "buf_lint_aspect")

buf = buf_lint_aspect(
    toolchain = "@rules_buf//tools/protoc-gen-buf-lint:toolchain_type",
    config = "@//:buf.yaml",
)
