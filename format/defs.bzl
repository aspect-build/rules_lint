"""Produce a multi-formatter that aggregates formatters.

Some formatter tools are automatically provided by default in rules_lint.
These are listed as defaults in the API docs below.

Other formatter binaries may be declared in your repository, and you can test them by running
them with Bazel.

For example, to add prettier, your `BUILD.bazel` file should contain:

```
load("@npm//:prettier/package_json.bzl", prettier = "bin")

prettier.prettier_binary(
    name = "prettier",
    # Allow the binary to be run outside bazel
    env = {"BAZEL_BINDIR": "."},
)
```

and you can test it with `bazel run //path/to:prettier -- --help`.

Then you can register it with `multi_formatter_binary`:

```
load("@aspect_rules_lint//format:defs.bzl", "multi_formatter_binary")

multi_formatter_binary(
    name = "format",
    javascript = ":prettier",
    ...
)
```
"""

load("//format/private:formatter_binary.bzl", _fmt = "multi_formatter_binary")

multi_formatter_binary_rule = _fmt

def multi_formatter_binary(
        name,
        jsonnet = Label("@multitool//tools/jsonnetfmt"),
        go = Label("@multitool//tools/gofumpt"),
        sh = Label("@multitool//tools/shfmt"),
        yaml = Label("@multitool//tools/yamlfmt"),
        **kwargs):
    "Wrapper macro around multi_formatter_binary_rule that sets defaults for some languages."
    _fmt(
        name = name,
        jsonnet = jsonnet,
        go = go,
        sh = sh,
        yaml = yaml,
        **kwargs
    )
