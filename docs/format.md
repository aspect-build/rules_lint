<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Produce a multi-formatter that aggregates formatters.

Some formatter tools are automatically provided by default in rules_lint.
These are listed as defaults in the API docs below.

Other formatter binaries may be declared in your repository.
You can test that they work by running them directly with `bazel run`.

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
)
```


<a id="format_multirun"></a>

## format_multirun

<pre>
format_multirun(<a href="#format_multirun-name">name</a>, <a href="#format_multirun-kwargs">kwargs</a>)
</pre>

Create a multirun binary for the given formatters.

Intended to be used with `bazel run` to update source files in-place.
To check formatting with `bazel test`, see [format_test](#format_test).

Also produces a target `[name].check` which does not edit files, rather it exits non-zero
if any sources require formatting.

Tools are provided by default for some languages.
These come from the `@multitool` repo.
Under --enable_bzlmod, rules_lint creates this automatically.
WORKSPACE users will have to set this up manually. See the release install snippet for an example.

Set any attribute to `False` to turn off that language altogether, rather than use a default tool.

Note that `javascript` is a special case which also formats TypeScript, TSX, JSON, CSS, and HTML.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="format_multirun-name"></a>name |  name of the resulting target, typically "format"   |  none |
| <a id="format_multirun-kwargs"></a>kwargs |  attributes named for each language, providing Label of a tool that formats it   |  none |


<a id="format_test"></a>

## format_test

<pre>
format_test(<a href="#format_test-name">name</a>, <a href="#format_test-srcs">srcs</a>, <a href="#format_test-workspace">workspace</a>, <a href="#format_test-no_sandbox">no_sandbox</a>, <a href="#format_test-tags">tags</a>, <a href="#format_test-kwargs">kwargs</a>)
</pre>

Create test for the given formatters.

Intended to be used with `bazel test` to verify files are formatted.
To format with `bazel run`, see [format_multirun](#format_multirun).


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="format_test-name"></a>name |  name of the resulting target, typically "format"   |  none |
| <a id="format_test-srcs"></a>srcs |  list of files to verify formatting. Required when no_sandbox is False.   |  <code>None</code> |
| <a id="format_test-workspace"></a>workspace |  a file in the root directory to verify formatting. Required when no_sandbox is True. Typically <code>//:WORKSPACE</code> or <code>//:MODULE.bazel</code> may be used.   |  <code>None</code> |
| <a id="format_test-no_sandbox"></a>no_sandbox |  Set to True to enable formatting all files in the workspace. This mode causes the test to be non-hermetic and it cannot be cached. Read the documentation in /docs/formatting.md.   |  <code>False</code> |
| <a id="format_test-tags"></a>tags |  tags to apply to generated targets. In 'no_sandbox' mode, <code>["no-sandbox", "no-cache", "external"]</code> are added to the tags.   |  <code>[]</code> |
| <a id="format_test-kwargs"></a>kwargs |  attributes named for each language, providing Label of a tool that formats it   |  none |


