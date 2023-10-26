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
    javascript = ":prettier",
    ...
)
```


<a id="multi_formatter_binary"></a>

## multi_formatter_binary

<pre>
multi_formatter_binary(<a href="#multi_formatter_binary-name">name</a>, <a href="#multi_formatter_binary-go">go</a>, <a href="#multi_formatter_binary-java">java</a>, <a href="#multi_formatter_binary-javascript">javascript</a>, <a href="#multi_formatter_binary-jsonnet">jsonnet</a>, <a href="#multi_formatter_binary-kotlin">kotlin</a>, <a href="#multi_formatter_binary-python">python</a>, <a href="#multi_formatter_binary-starlark">starlark</a>, <a href="#multi_formatter_binary-swift">swift</a>,
                       <a href="#multi_formatter_binary-terraform">terraform</a>)
</pre>

Produces an executable that aggregates the supplied formatter binaries

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="multi_formatter_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="multi_formatter_binary-go"></a>go |  a binary target that runs go fmt   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary-java"></a>java |  a binary target that runs google-java-format   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary-javascript"></a>javascript |  a binary target that runs prettier   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary-jsonnet"></a>jsonnet |  a binary target that runs jsonnetfmt   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary-kotlin"></a>kotlin |  a binary target that runs ktfmt   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary-python"></a>python |  a binary target that runs ruff   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary-starlark"></a>starlark |  a binary target that runs buildifier   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary-swift"></a>swift |  a binary target that runs swiftformat   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary-terraform"></a>terraform |  a binary target that runs terraform   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |


