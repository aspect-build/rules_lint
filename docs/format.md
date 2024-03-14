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

Then you can register it with `format_multirun`:

```
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

format_multirun(
    name = "format",
    javascript = ":prettier",
    ...
)
```


<a id="format_multirun_rule"></a>

## format_multirun_rule

<pre>
format_multirun_rule(<a href="#format_multirun_rule-name">name</a>, <a href="#format_multirun_rule-cc">cc</a>, <a href="#format_multirun_rule-go">go</a>, <a href="#format_multirun_rule-java">java</a>, <a href="#format_multirun_rule-javascript">javascript</a>, <a href="#format_multirun_rule-jsonnet">jsonnet</a>, <a href="#format_multirun_rule-kotlin">kotlin</a>, <a href="#format_multirun_rule-markdown">markdown</a>, <a href="#format_multirun_rule-protobuf">protobuf</a>,
                            <a href="#format_multirun_rule-python">python</a>, <a href="#format_multirun_rule-scala">scala</a>, <a href="#format_multirun_rule-sh">sh</a>, <a href="#format_multirun_rule-sql">sql</a>, <a href="#format_multirun_rule-starlark">starlark</a>, <a href="#format_multirun_rule-swift">swift</a>, <a href="#format_multirun_rule-terraform">terraform</a>, <a href="#format_multirun_rule-yaml">yaml</a>)
</pre>

Produces an executable that aggregates the supplied formatter binaries

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="format_multirun_rule-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="format_multirun_rule-cc"></a>cc |  a binary target that runs clang-format (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-go"></a>go |  a binary target that runs gofmt (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-java"></a>java |  a binary target that runs java-format (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-javascript"></a>javascript |  a binary target that runs prettier (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-jsonnet"></a>jsonnet |  a binary target that runs jsonnetfmt (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-kotlin"></a>kotlin |  a binary target that runs ktfmt (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-markdown"></a>markdown |  a binary target that runs prettier-md (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-protobuf"></a>protobuf |  a binary target that runs buf (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-python"></a>python |  a binary target that runs ruff (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-scala"></a>scala |  a binary target that runs scalafmt (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-sh"></a>sh |  a binary target that runs shfmt (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-sql"></a>sql |  a binary target that runs prettier-sql (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-starlark"></a>starlark |  a binary target that runs buildifier (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-swift"></a>swift |  a binary target that runs swiftformat (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-terraform"></a>terraform |  a binary target that runs terraform-fmt (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="format_multirun_rule-yaml"></a>yaml |  a binary target that runs yamlfmt (or another tool with compatible CLI arguments)   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |


<a id="format_multirun"></a>

## format_multirun

<pre>
format_multirun(<a href="#format_multirun-name">name</a>, <a href="#format_multirun-kwargs">kwargs</a>)
</pre>

Wrapper macro around format_multirun_rule that sets defaults for some languages.

These come from the `@multitool` repo.
Under --enable_bzlmod, rules_lint creates this automatically.
WORKSPACE users will have to set this up manually. See the release install snippet for an example.

Set any attribute to `False` to turn off that language altogether, rather than use a default tool.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="format_multirun-name"></a>name |  <p align="center"> - </p>   |  none |
| <a id="format_multirun-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


