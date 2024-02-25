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
multi_formatter_binary(<a href="#multi_formatter_binary-name">name</a>, <a href="#multi_formatter_binary-jsonnet">jsonnet</a>, <a href="#multi_formatter_binary-go">go</a>, <a href="#multi_formatter_binary-sh">sh</a>, <a href="#multi_formatter_binary-yaml">yaml</a>, <a href="#multi_formatter_binary-kwargs">kwargs</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="multi_formatter_binary-name"></a>name |  <p align="center"> - </p>   |  none |
| <a id="multi_formatter_binary-jsonnet"></a>jsonnet |  <p align="center"> - </p>   |  <code>Label("@multitool//tools/jsonnetfmt:jsonnetfmt")</code> |
| <a id="multi_formatter_binary-go"></a>go |  <p align="center"> - </p>   |  <code>Label("@multitool//tools/gofumpt:gofumpt")</code> |
| <a id="multi_formatter_binary-sh"></a>sh |  <p align="center"> - </p>   |  <code>Label("@multitool//tools/shfmt:shfmt")</code> |
| <a id="multi_formatter_binary-yaml"></a>yaml |  <p align="center"> - </p>   |  <code>Label("@multitool//tools/yamlfmt:yamlfmt")</code> |
| <a id="multi_formatter_binary-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


