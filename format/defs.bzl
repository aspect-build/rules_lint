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

Then you can register it with `format_multirun`:

```
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

format_multirun(
    name = "format",
    javascript = ":prettier",
    ...
)
```
"""

load("//format/private:formatter_binary.bzl", _fmt = "format_multirun")

format_multirun_rule = _fmt

def format_multirun(name, **kwargs):
    """Wrapper macro around format_multirun_rule that sets defaults for some languages.

    These come from the `@multitool` repo.
    Under --enable_bzlmod, rules_lint creates this automatically.
    WORKSPACE users will have to set this up manually. See the release install snippet for an example.

    Set any attribute to `False` to turn off that language altogether, rather than use a default tool.
    """

    _fmt(
        name = name,
        # Logic:
        # - if there's no value for this key, the user omitted it, so use our default
        # - if there is a value, and it's False, then pass None to the underlying rule
        #   (and make sure we don't eagerly reference @multitool in case it isn't defined)
        # - otherwise use the user-supplied value
        jsonnet = kwargs.pop("jsonnet", Label("@multitool//tools/jsonnetfmt")) or None,
        go = kwargs.pop("go", Label("@multitool//tools/gofumpt")) or None,
        sh = kwargs.pop("sh", Label("@multitool//tools/shfmt")) or None,
        yaml = kwargs.pop("yaml", Label("@multitool//tools/yamlfmt")) or None,
        **kwargs
    )
