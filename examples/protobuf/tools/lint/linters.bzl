"Define linter aspects"

load("@aspect_rules_lint//lint:buf.bzl", "lint_buf_aspect")
load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")

buf = lint_buf_aspect(
    config = Label("@//:buf.yaml"),
)

buf_test = lint_test(aspect = buf)

# an example of setting up a buf aspect for a v2 buf.yaml listing `modules`
buf_modules = lint_buf_aspect(
    config = Label("@//modules:buf.yaml"),
    infer_module = True,
)

buf_modules_test = lint_test(aspect = buf_modules)
