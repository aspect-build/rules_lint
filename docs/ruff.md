<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a Ruff lint aspect that visits py_library rules.

Typical usage:

```
load("@aspect_rules_lint//lint:ruff.bzl", "ruff_aspect")

ruff = ruff_aspect(
    binary = "@multitool//tools/ruff",
    configs = "@@//:.ruff.toml",
)
```

## Using a specific ruff version

In `WORKSPACE`, fetch the desired version from https://github.com/astral-sh/ruff/releases

```starlark
load("@aspect_rules_lint//lint:ruff.bzl", "fetch_ruff")

# Specify a tag from the ruff repository
fetch_ruff("v0.4.10")
```

In `tools/lint/BUILD.bazel`, select the tool for the host platform:

```starlark
alias(
    name = "ruff",
    actual = select({
        "@bazel_tools//src/conditions:linux_x86_64": "@ruff_x86_64-unknown-linux-gnu//:ruff",
        "@bazel_tools//src/conditions:linux_aarch64": "@ruff_aarch64-unknown-linux-gnu//:ruff",
        "@bazel_tools//src/conditions:darwin_arm64": "@ruff_aarch64-apple-darwin//:ruff",
        "@bazel_tools//src/conditions:darwin_x86_64": "@ruff_x86_64-apple-darwin//:ruff",
        "@bazel_tools//src/conditions:windows_x64": "@ruff_x86_64-pc-windows-msvc//:ruff.exe",
    }),
)
```

Finally, reference this tool alias rather than the one from `@multitool`:

```starlark
ruff = lint_ruff_aspect(
    binary = "@@//tools/lint:ruff",
    ...
)
```


<a id="ruff_workaround_20269"></a>

## ruff_workaround_20269

<pre>
ruff_workaround_20269(<a href="#ruff_workaround_20269-name">name</a>, <a href="#ruff_workaround_20269-build_file_content">build_file_content</a>, <a href="#ruff_workaround_20269-repo_mapping">repo_mapping</a>, <a href="#ruff_workaround_20269-sha256">sha256</a>, <a href="#ruff_workaround_20269-strip_prefix">strip_prefix</a>, <a href="#ruff_workaround_20269-url">url</a>)
</pre>

Workaround for https://github.com/bazelbuild/bazel/issues/20269

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="ruff_workaround_20269-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="ruff_workaround_20269-build_file_content"></a>build_file_content |  -   | String | optional | <code>""</code> |
| <a id="ruff_workaround_20269-repo_mapping"></a>repo_mapping |  A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.&lt;p&gt;For example, an entry <code>"@foo": "@bar"</code> declares that, for any time this repository depends on <code>@foo</code> (such as a dependency on <code>@foo//some:target</code>, it should actually resolve that dependency within globally-declared <code>@bar</code> (<code>@bar//some:target</code>).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | required |  |
| <a id="ruff_workaround_20269-sha256"></a>sha256 |  -   | String | optional | <code>""</code> |
| <a id="ruff_workaround_20269-strip_prefix"></a>strip_prefix |  unlike http_archive, any value causes us to pass --strip-components=1 to tar   | String | optional | <code>""</code> |
| <a id="ruff_workaround_20269-url"></a>url |  -   | String | optional | <code>""</code> |


<a id="fetch_ruff"></a>

## fetch_ruff

<pre>
fetch_ruff(<a href="#fetch_ruff-tag">tag</a>)
</pre>

A repository macro used from WORKSPACE to fetch ruff binaries.

Allows the user to select a particular ruff version, rather than get whatever is pinned in the `multitool.lock.json` file.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="fetch_ruff-tag"></a>tag |  a tag of ruff that we have mirrored, e.g. <code>v0.1.0</code>   |  none |


<a id="lint_ruff_aspect"></a>

## lint_ruff_aspect

<pre>
lint_ruff_aspect(<a href="#lint_ruff_aspect-binary">binary</a>, <a href="#lint_ruff_aspect-configs">configs</a>, <a href="#lint_ruff_aspect-rule_kinds">rule_kinds</a>)
</pre>

A factory function to create a linter aspect.

Attrs:
    binary: a ruff executable
    configs: ruff config file(s) (`pyproject.toml`, `ruff.toml`, or `.ruff.toml`)
    rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_ruff_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="lint_ruff_aspect-configs"></a>configs |  <p align="center"> - </p>   |  none |
| <a id="lint_ruff_aspect-rule_kinds"></a>rule_kinds |  <p align="center"> - </p>   |  <code>["py_binary", "py_library", "py_test"]</code> |


<a id="ruff_action"></a>

## ruff_action

<pre>
ruff_action(<a href="#ruff_action-ctx">ctx</a>, <a href="#ruff_action-executable">executable</a>, <a href="#ruff_action-srcs">srcs</a>, <a href="#ruff_action-config">config</a>, <a href="#ruff_action-stdout">stdout</a>, <a href="#ruff_action-exit_code">exit_code</a>)
</pre>

Run ruff as an action under Bazel.

Ruff will select the configuration file to use for each source file, as documented here:
https://docs.astral.sh/ruff/configuration/#config-file-discovery

Note: all config files are passed to the action.
This means that a change to any config file invalidates the action cache entries for ALL
ruff actions.

However this is needed because:

1. ruff has an `extend` field, so it may need to read more than one config file
2. ruff's logic for selecting the appropriate config needs to read the file content to detect
  a `[tool.ruff]` section.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="ruff_action-ctx"></a>ctx |  Bazel Rule or Aspect evaluation context   |  none |
| <a id="ruff_action-executable"></a>executable |  label of the the ruff program   |  none |
| <a id="ruff_action-srcs"></a>srcs |  python files to be linted   |  none |
| <a id="ruff_action-config"></a>config |  labels of ruff config files (pyproject.toml, ruff.toml, or .ruff.toml)   |  none |
| <a id="ruff_action-stdout"></a>stdout |  output file of linter results to generate   |  none |
| <a id="ruff_action-exit_code"></a>exit_code |  output file to write the exit code. If None, then fail the build when ruff exits non-zero. See https://github.com/astral-sh/ruff/blob/dfe4291c0b7249ae892f5f1d513e6f1404436c13/docs/linter.md#exit-codes   |  <code>None</code> |


<a id="ruff_fix"></a>

## ruff_fix

<pre>
ruff_fix(<a href="#ruff_fix-ctx">ctx</a>, <a href="#ruff_fix-executable">executable</a>, <a href="#ruff_fix-srcs">srcs</a>, <a href="#ruff_fix-config">config</a>, <a href="#ruff_fix-patch">patch</a>, <a href="#ruff_fix-stdout">stdout</a>, <a href="#ruff_fix-exit_code">exit_code</a>)
</pre>

Create a Bazel Action that spawns ruff with --fix.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="ruff_fix-ctx"></a>ctx |  an action context OR aspect context   |  none |
| <a id="ruff_fix-executable"></a>executable |  struct with _ruff and _patcher field   |  none |
| <a id="ruff_fix-srcs"></a>srcs |  list of file objects to lint   |  none |
| <a id="ruff_fix-config"></a>config |  labels of ruff config files (pyproject.toml, ruff.toml, or .ruff.toml)   |  none |
| <a id="ruff_fix-patch"></a>patch |  output file containing the applied fixes that can be applied with the patch(1) command.   |  none |
| <a id="ruff_fix-stdout"></a>stdout |  output file of linter results to generate   |  none |
| <a id="ruff_fix-exit_code"></a>exit_code |  output file to write the exit code   |  none |


