<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a flake8 lint aspect that visits py_library rules.

Typical usage:

First, fetch the flake8 package via your standard requirements file and pip calls.

Then, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")
py_console_script_binary(
    name = "flake8",
    pkg = "@pip//flake8:pkg",
)
```

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:flake8.bzl", "lint_flake8_aspect")

flake8 = lint_flake8_aspect(
    binary = Label("//tools/lint:flake8"),
    config = Label("//:.flake8"),
)
```

<a id="flake8_action"></a>

## flake8_action

<pre>
load("@aspect_rules_lint//lint:flake8.bzl", "flake8_action")

flake8_action(<a href="#flake8_action-ctx">ctx</a>, <a href="#flake8_action-executable">executable</a>, <a href="#flake8_action-srcs">srcs</a>, <a href="#flake8_action-config">config</a>, <a href="#flake8_action-stdout">stdout</a>, <a href="#flake8_action-exit_code">exit_code</a>, <a href="#flake8_action-options">options</a>)
</pre>

Run flake8 as an action under Bazel.

Based on https://flake8.pycqa.org/en/latest/user/invocation.html


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="flake8_action-ctx"></a>ctx |  Bazel Rule or Aspect evaluation context   |  none |
| <a id="flake8_action-executable"></a>executable |  label of the the flake8 program   |  none |
| <a id="flake8_action-srcs"></a>srcs |  python files to be linted   |  none |
| <a id="flake8_action-config"></a>config |  label of the flake8 config file (setup.cfg, tox.ini, or .flake8)   |  none |
| <a id="flake8_action-stdout"></a>stdout |  output file containing stdout of flake8   |  none |
| <a id="flake8_action-exit_code"></a>exit_code |  output file containing exit code of flake8 If None, then fail the build when flake8 exits non-zero.   |  `None` |
| <a id="flake8_action-options"></a>options |  additional command-line options, see https://flake8.pycqa.org/en/latest/user/options.html   |  `[]` |


<a id="lint_flake8_aspect"></a>

## lint_flake8_aspect

<pre>
load("@aspect_rules_lint//lint:flake8.bzl", "lint_flake8_aspect")

lint_flake8_aspect(<a href="#lint_flake8_aspect-binary">binary</a>, <a href="#lint_flake8_aspect-config">config</a>, <a href="#lint_flake8_aspect-rule_kinds">rule_kinds</a>)
</pre>

A factory function to create a linter aspect.

Attrs:
    binary: a flake8 executable. Can be obtained from rules_python like so:

        load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

        py_console_script_binary(
            name = "flake8",
            pkg = "@pip//flake8:pkg",
        )

    config: the flake8 config file (`setup.cfg`, `tox.ini`, or `.flake8`)

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_flake8_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="lint_flake8_aspect-config"></a>config |  <p align="center"> - </p>   |  none |
| <a id="lint_flake8_aspect-rule_kinds"></a>rule_kinds |  <p align="center"> - </p>   |  `["py_binary", "py_library"]` |


