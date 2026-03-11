load("@npm//:npm-groovy-lint/package_json.bzl", groovy_bin = "bin")

groovy_bin.npm_groovy_lint_binary(
    name = "groovy-lint",
    data = [":.groovylintrc.json"],
    env = {"BAZEL_BINDIR": "."},
    fixed_args = [
        "--config=\"$$JS_BINARY__RUNFILES\"/$(rlocationpath :.groovylintrc.json)",
    ],
)
