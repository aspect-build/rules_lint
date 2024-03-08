<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Produce a multi-formatter that aggregates formatters.

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


<a id="multi_formatter_binary_rule"></a>

## multi_formatter_binary_rule

<pre>
multi_formatter_binary_rule(<a href="#multi_formatter_binary_rule-name">name</a>, <a href="#multi_formatter_binary_rule-cc">cc</a>, <a href="#multi_formatter_binary_rule-go">go</a>, <a href="#multi_formatter_binary_rule-java">java</a>, <a href="#multi_formatter_binary_rule-javascript">javascript</a>, <a href="#multi_formatter_binary_rule-jsonnet">jsonnet</a>, <a href="#multi_formatter_binary_rule-kotlin">kotlin</a>, <a href="#multi_formatter_binary_rule-markdown">markdown</a>, <a href="#multi_formatter_binary_rule-protobuf">protobuf</a>,
                            <a href="#multi_formatter_binary_rule-python">python</a>, <a href="#multi_formatter_binary_rule-scala">scala</a>, <a href="#multi_formatter_binary_rule-sh">sh</a>, <a href="#multi_formatter_binary_rule-sql">sql</a>, <a href="#multi_formatter_binary_rule-starlark">starlark</a>, <a href="#multi_formatter_binary_rule-swift">swift</a>, <a href="#multi_formatter_binary_rule-terraform">terraform</a>, <a href="#multi_formatter_binary_rule-yaml">yaml</a>)
</pre>

Produces an executable that aggregates the supplied formatter binaries

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="multi_formatter_binary_rule-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="multi_formatter_binary_rule-cc"></a>cc |  a binary target that runs clang-format (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-go"></a>go |  a binary target that runs gofmt (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-java"></a>java |  a binary target that runs java-format (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-javascript"></a>javascript |  a binary target that runs prettier (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-jsonnet"></a>jsonnet |  a binary target that runs jsonnetfmt (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-kotlin"></a>kotlin |  a binary target that runs ktfmt (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-markdown"></a>markdown |  a binary target that runs prettier-md (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-protobuf"></a>protobuf |  a binary target that runs buf (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-python"></a>python |  a binary target that runs ruff (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-scala"></a>scala |  a binary target that runs scalafmt (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-sh"></a>sh |  a binary target that runs shfmt (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-sql"></a>sql |  a binary target that runs prettier-sql (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-starlark"></a>starlark |  a binary target that runs buildifier (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-swift"></a>swift |  a binary target that runs swiftformat (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-terraform"></a>terraform |  a binary target that runs terraform-fmt (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="multi_formatter_binary_rule-yaml"></a>yaml |  a binary target that runs yamlfmt (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |


<a id="multi_formatter_binary"></a>

## multi_formatter_binary

<pre>
multi_formatter_binary(<a href="#multi_formatter_binary-name">name</a>, <a href="#multi_formatter_binary-kwargs">kwargs</a>)
</pre>

Wrapper macro around multi_formatter_binary_rule that sets defaults for some languages.

These come from the `@multitool` repo.
Under --enable_bzlmod, rules_lint creates this automatically.
WORKSPACE users will have to set this up manually. See the release install snippet for an example.

Set any attribute to `False` to turn off that language altogether, rather than use a default tool.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="multi_formatter_binary-name"></a>name |  <p align="center"> - </p>   |  none |
| <a id="multi_formatter_binary-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


