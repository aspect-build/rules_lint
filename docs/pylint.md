<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a pylint lint aspect that visits Python rules.

Typical usage:

First, fetch the pylint package via your standard requirements file and pip calls.

Then, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

py_console_script_binary(
    name = "pylint",
    pkg = "@pip//pylint:pkg",
)
```

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:pylint.bzl", "lint_pylint_aspect")

pylint = lint_pylint_aspect(
    binary = Label("//tools/lint:pylint"),
    config = Label("//:.pylintrc"),
)
```

<a id="lint_pylint_aspect"></a>

## lint_pylint_aspect

<pre>
load("@aspect_rules_lint//lint:pylint.bzl", "lint_pylint_aspect")

lint_pylint_aspect(<a href="#lint_pylint_aspect-binary">binary</a>, <a href="#lint_pylint_aspect-config">config</a>, <a href="#lint_pylint_aspect-rule_kinds">rule_kinds</a>, <a href="#lint_pylint_aspect-filegroup_tags">filegroup_tags</a>)
</pre>

A factory function to create a linter aspect.

Attrs:
    binary: a pylint executable. Can be obtained from rules_python like so:

        load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

        py_console_script_binary(
            name = "pylint",
            pkg = "@pip//pylint:pkg",
        )

    config: the pylint config file (`pyproject.toml`, `pylintrc`, or `.pylintrc`)
    rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect
    filegroup_tags: filegroups tagged with these tags will also be visited by the aspect

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_pylint_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="lint_pylint_aspect-config"></a>config |  <p align="center"> - </p>   |  none |
| <a id="lint_pylint_aspect-rule_kinds"></a>rule_kinds |  <p align="center"> - </p>   |  `["py_binary", "py_library", "py_test"]` |
| <a id="lint_pylint_aspect-filegroup_tags"></a>filegroup_tags |  <p align="center"> - </p>   |  `["python", "lint-with-pylint"]` |


<a id="pylint_action"></a>

## pylint_action

<pre>
load("@aspect_rules_lint//lint:pylint.bzl", "pylint_action")

pylint_action(<a href="#pylint_action-ctx">ctx</a>, <a href="#pylint_action-executable">executable</a>, <a href="#pylint_action-srcs">srcs</a>, <a href="#pylint_action-config">config</a>, <a href="#pylint_action-stdout">stdout</a>, <a href="#pylint_action-exit_code">exit_code</a>, <a href="#pylint_action-options">options</a>)
</pre>

Run pylint as an action under Bazel.

Based on https://pylint.readthedocs.io/en/stable/user_guide/run.html


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="pylint_action-ctx"></a>ctx |  Bazel Rule or Aspect evaluation context   |  none |
| <a id="pylint_action-executable"></a>executable |  label of the pylint program   |  none |
| <a id="pylint_action-srcs"></a>srcs |  python files to be linted   |  none |
| <a id="pylint_action-config"></a>config |  label of the pylint config file (pyproject.toml, .pylintrc, or setup.cfg)   |  none |
| <a id="pylint_action-stdout"></a>stdout |  output file containing stdout of pylint   |  none |
| <a id="pylint_action-exit_code"></a>exit_code |  output file containing exit code of pylint If None, then fail the build when pylint exits non-zero.   |  `None` |
| <a id="pylint_action-options"></a>options |  additional command-line options   |  `[]` |


