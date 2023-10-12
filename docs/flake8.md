<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a flake8 lint aspect that visits py_library rules.

Typical usage:

```
load("@aspect_rules_lint//lint:flake8.bzl", "flake8_aspect")

flake8 = flake8_aspect(
    binary = "@@//:flake8",
    config = "@@//:.flake8",
)
```


<a id="flake8_action"></a>

## flake8_action

<pre>
flake8_action(<a href="#flake8_action-ctx">ctx</a>, <a href="#flake8_action-executable">executable</a>, <a href="#flake8_action-srcs">srcs</a>, <a href="#flake8_action-config">config</a>, <a href="#flake8_action-report">report</a>, <a href="#flake8_action-use_exit_code">use_exit_code</a>)
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
| <a id="flake8_action-report"></a>report |  output file to generate   |  none |
| <a id="flake8_action-use_exit_code"></a>use_exit_code |  whether to fail the build when a lint violation is reported   |  <code>False</code> |


<a id="flake8_aspect"></a>

## flake8_aspect

<pre>
flake8_aspect(<a href="#flake8_aspect-binary">binary</a>, <a href="#flake8_aspect-config">config</a>)
</pre>

A factory function to create a linter aspect.

Attrs:
    binary: a flake8 executable. Can be obtained from rules_python like so:

        ```
        load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

        py_console_script_binary(
            name = "flake8",
            pkg = "@pip//flake8:pkg",
        )
        ```
    config: the flake8 config file (`setup.cfg`, `tox.ini`, or `.flake8`)

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="flake8_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="flake8_aspect-config"></a>config |  <p align="center"> - </p>   |  none |


