"""Produce a multi-formatter that aggregates the supplier formatters.

Each formatter binary should already be declared in your repository, and you can test them by running
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
    formatters = {
        "JavaScript": ":prettier",
    },
)
```
"""

load("//format/private:formatter_binary.bzl", _fmt = "multi_formatter_binary")

def multi_formatter_binary(name, formatters):
    """Declares a formatter aggregator

    Args:
        name: name of the resulting executable target, typically "format"
        formatters: a dictionary: each key is a supported language, and the value is the formatter binary to use
    """
    _fmt(
        name = name,
        # reverse the dictionary - bazel only supports labels as keys
        formatters = {v: k for k, v in formatters.items()},
    )
