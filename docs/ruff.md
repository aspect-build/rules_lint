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


<a id="lint_ruff_aspect"></a>

## lint_ruff_aspect

<pre>
lint_ruff_aspect(<a href="#lint_ruff_aspect-binary">binary</a>, <a href="#lint_ruff_aspect-configs">configs</a>)
</pre>

A factory function to create a linter aspect.

Attrs:
    binary: a ruff executable.
    configs: ruff config file(s) (`pyproject.toml`, `ruff.toml`, or `.ruff.toml`)

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_ruff_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="lint_ruff_aspect-configs"></a>configs |  <p align="center"> - </p>   |  none |


<a id="ruff_action"></a>

## ruff_action

<pre>
ruff_action(<a href="#ruff_action-ctx">ctx</a>, <a href="#ruff_action-executable">executable</a>, <a href="#ruff_action-srcs">srcs</a>, <a href="#ruff_action-config">config</a>, <a href="#ruff_action-report">report</a>, <a href="#ruff_action-use_exit_code">use_exit_code</a>)
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
| <a id="ruff_action-report"></a>report |  output file to generate   |  none |
| <a id="ruff_action-use_exit_code"></a>use_exit_code |  whether to fail the build when a lint violation is reported   |  <code>False</code> |


<a id="ruff_fix"></a>

## ruff_fix

<pre>
ruff_fix(<a href="#ruff_fix-ctx">ctx</a>, <a href="#ruff_fix-executable">executable</a>, <a href="#ruff_fix-srcs">srcs</a>, <a href="#ruff_fix-config">config</a>, <a href="#ruff_fix-patch">patch</a>)
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


