<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Configures [yamllint](https://yamllint.readthedocs.io/) to run as a Bazel aspect.

Typical usage:

Create an executable target for yamllint, for example in `tools/lint/BUILD.bazel`:

```starlark
load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

py_console_script_binary(
    name = "yamllint",
    pkg = "@pip//yamllint:pkg",
)
```

Then declare the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:yamllint.bzl", "lint_yamllint_aspect")

yamllint = lint_yamllint_aspect(
    binary = Label("//tools/lint:yamllint"),
    config = Label("//:.yamllint"),
)
```

Finally, opt YAML sources into linting by tagging a `filegroup` with `lint-with-yamllint`, or by
providing a custom `rule_kinds` list that matches your YAML rules.

<a id="lint_yamllint_aspect"></a>

## lint_yamllint_aspect

<pre>
load("@aspect_rules_lint//lint:yamllint.bzl", "lint_yamllint_aspect")

lint_yamllint_aspect(<a href="#lint_yamllint_aspect-binary">binary</a>, <a href="#lint_yamllint_aspect-config">config</a>, <a href="#lint_yamllint_aspect-rule_kinds">rule_kinds</a>, <a href="#lint_yamllint_aspect-filegroup_tags">filegroup_tags</a>, <a href="#lint_yamllint_aspect-extra_args">extra_args</a>)
</pre>

Create a yamllint aspect.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_yamllint_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="lint_yamllint_aspect-config"></a>config |  <p align="center"> - </p>   |  none |
| <a id="lint_yamllint_aspect-rule_kinds"></a>rule_kinds |  <p align="center"> - </p>   |  `["yaml_library"]` |
| <a id="lint_yamllint_aspect-filegroup_tags"></a>filegroup_tags |  <p align="center"> - </p>   |  `["lint-with-yamllint"]` |
| <a id="lint_yamllint_aspect-extra_args"></a>extra_args |  <p align="center"> - </p>   |  `[]` |


<a id="yamllint_action"></a>

## yamllint_action

<pre>
load("@aspect_rules_lint//lint:yamllint.bzl", "yamllint_action")

yamllint_action(<a href="#yamllint_action-ctx">ctx</a>, <a href="#yamllint_action-executable">executable</a>, <a href="#yamllint_action-srcs">srcs</a>, <a href="#yamllint_action-config">config</a>, <a href="#yamllint_action-stdout">stdout</a>, <a href="#yamllint_action-exit_code">exit_code</a>, <a href="#yamllint_action-format">format</a>, <a href="#yamllint_action-options">options</a>)
</pre>

Run yamllint as an action under Bazel.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="yamllint_action-ctx"></a>ctx |  Bazel Rule or Aspect evaluation context   |  none |
| <a id="yamllint_action-executable"></a>executable |  File representing the yamllint program   |  none |
| <a id="yamllint_action-srcs"></a>srcs |  YAML files to lint   |  none |
| <a id="yamllint_action-config"></a>config |  yamllint configuration file   |  none |
| <a id="yamllint_action-stdout"></a>stdout |  output file for yamllint stdout   |  none |
| <a id="yamllint_action-exit_code"></a>exit_code |  optional output file for exit code. If absent, non-zero exits fail the build.   |  `None` |
| <a id="yamllint_action-format"></a>format |  optional formatter passed via `-f`   |  `None` |
| <a id="yamllint_action-options"></a>options |  additional command-line options   |  `[]` |


