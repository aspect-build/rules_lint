<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Produce a multi-formatter that aggregates the supplier formatters.

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


<a id="multi_formatter_binary"></a>

## multi_formatter_binary

<pre>
multi_formatter_binary(<a href="#multi_formatter_binary-name">name</a>, <a href="#multi_formatter_binary-formatters">formatters</a>)
</pre>

Declares a formatter aggregator

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="multi_formatter_binary-name"></a>name |  name of the resulting executable target, typically "format"   |  none |
| <a id="multi_formatter_binary-formatters"></a>formatters |  a dictionary: each key is a supported language, and the value is the formatter binary to use   |  none |


