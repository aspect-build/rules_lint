<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Configures [Stylelint](https://stylelint.io/) to run as a Bazel aspect

First, all CSS sources must be the srcs of some Bazel rule.
You can use a `filegroup` with `lint-with-stylelint` in the `tags`:

```python
filegroup(
    name = "css",
    srcs = glob(["*.css"]),
    tags = ["lint-with-stylelint"],
)
```

See the `filegroup_tags` and `rule_kinds` attributes below to customize this behavior.

## Usage

```starlark
load("@aspect_rules_lint//lint:vale.bzl", "vale_aspect")

vale = vale_aspect(
    binary = "@@//tools/lint:vale",
    # A copy_to_bin rule that places the .vale.ini file into bazel-bin
    config = "@@//:.vale_ini",
    # Optional.
    # A copy_to_directory rule that "installs" custom styles together into a single folder
    styles = "@@//tools/lint:vale_styles",
)
```


<a id="lint_stylelint_aspect"></a>

## lint_stylelint_aspect

<pre>
lint_stylelint_aspect(<a href="#lint_stylelint_aspect-binary">binary</a>, <a href="#lint_stylelint_aspect-config">config</a>, <a href="#lint_stylelint_aspect-rule_kinds">rule_kinds</a>, <a href="#lint_stylelint_aspect-filegroup_tags">filegroup_tags</a>)
</pre>

A factory function to create a linter aspect.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_stylelint_aspect-binary"></a>binary |  the stylelint binary, typically a rule like<br><br><pre><code> load("@npm//:stylelint/package_json.bzl", stylelint_bin = "bin") stylelint_bin.stylelint_binary(name = "stylelint") </code></pre>   |  none |
| <a id="lint_stylelint_aspect-config"></a>config |  <p align="center"> - </p>   |  none |
| <a id="lint_stylelint_aspect-rule_kinds"></a>rule_kinds |  which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect   |  <code>["css_library"]</code> |
| <a id="lint_stylelint_aspect-filegroup_tags"></a>filegroup_tags |  <p align="center"> - </p>   |  <code>["lint-with-stylelint"]</code> |


<a id="stylelint_action"></a>

## stylelint_action

<pre>
stylelint_action(<a href="#stylelint_action-ctx">ctx</a>, <a href="#stylelint_action-executable">executable</a>, <a href="#stylelint_action-srcs">srcs</a>, <a href="#stylelint_action-config">config</a>, <a href="#stylelint_action-stderr">stderr</a>, <a href="#stylelint_action-exit_code">exit_code</a>, <a href="#stylelint_action-env">env</a>, <a href="#stylelint_action-options">options</a>)
</pre>

Spawn stylelint as a Bazel action

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="stylelint_action-ctx"></a>ctx |  an action context OR aspect context   |  none |
| <a id="stylelint_action-executable"></a>executable |  struct with an _stylelint field   |  none |
| <a id="stylelint_action-srcs"></a>srcs |  list of file objects to lint   |  none |
| <a id="stylelint_action-config"></a>config |  <p align="center"> - </p>   |  none |
| <a id="stylelint_action-stderr"></a>stderr |  output file containing the stderr or --output-file of stylelint   |  none |
| <a id="stylelint_action-exit_code"></a>exit_code |  output file containing the exit code of stylelint. If None, then fail the build when eslint exits non-zero. Exit codes may be:     1 - fatal error     2 - lint problem     64 - invalid CLI usage     78 - invalid configuration file   |  <code>None</code> |
| <a id="stylelint_action-env"></a>env |  environment variables for stylelint   |  <code>{}</code> |
| <a id="stylelint_action-options"></a>options |  additional command-line arguments   |  <code>[]</code> |


<a id="stylelint_fix"></a>

## stylelint_fix

<pre>
stylelint_fix(<a href="#stylelint_fix-ctx">ctx</a>, <a href="#stylelint_fix-executable">executable</a>, <a href="#stylelint_fix-srcs">srcs</a>, <a href="#stylelint_fix-config">config</a>, <a href="#stylelint_fix-patch">patch</a>, <a href="#stylelint_fix-stderr">stderr</a>, <a href="#stylelint_fix-exit_code">exit_code</a>, <a href="#stylelint_fix-env">env</a>, <a href="#stylelint_fix-options">options</a>)
</pre>

Create a Bazel Action that spawns stylelint with --fix.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="stylelint_fix-ctx"></a>ctx |  an action context OR aspect context   |  none |
| <a id="stylelint_fix-executable"></a>executable |  struct with a _stylelint field   |  none |
| <a id="stylelint_fix-srcs"></a>srcs |  list of file objects to lint   |  none |
| <a id="stylelint_fix-config"></a>config |  <p align="center"> - </p>   |  none |
| <a id="stylelint_fix-patch"></a>patch |  output file containing the applied fixes that can be applied with the patch(1) command.   |  none |
| <a id="stylelint_fix-stderr"></a>stderr |  output file containing the stderr or --output-file of stylelint   |  none |
| <a id="stylelint_fix-exit_code"></a>exit_code |  output file containing the exit code of stylelint   |  none |
| <a id="stylelint_fix-env"></a>env |  environment variaables for eslint   |  <code>{}</code> |
| <a id="stylelint_fix-options"></a>options |  additional command line options   |  <code>[]</code> |


