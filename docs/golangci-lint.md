<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a golangci-lint lint aspect that visits go_library, go_test, and go_binary rules.

```
load("@aspect_rules_lint//lint:golangci-lint.bzl", "golangci_lint_aspect")

golangci_lint = golangci_lint_aspect(
    binary = "@@//tools:golangci-lint",
    config = "@@//:.golangci.yaml",
)
```


<a id="fetch_golangci_lint"></a>

## fetch_golangci_lint

<pre>
fetch_golangci_lint()
</pre>





<a id="golangci_lint_action"></a>

## golangci_lint_action

<pre>
golangci_lint_action(<a href="#golangci_lint_action-ctx">ctx</a>, <a href="#golangci_lint_action-executable">executable</a>, <a href="#golangci_lint_action-srcs">srcs</a>, <a href="#golangci_lint_action-config">config</a>, <a href="#golangci_lint_action-report">report</a>, <a href="#golangci_lint_action-use_exit_code">use_exit_code</a>)
</pre>

Run golangci-lint as an action under Bazel.

Based on https://github.com/golangci/golangci-lint


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="golangci_lint_action-ctx"></a>ctx |  Bazel Rule or Aspect evaluation context   |  none |
| <a id="golangci_lint_action-executable"></a>executable |  label of the the golangci-lint program   |  none |
| <a id="golangci_lint_action-srcs"></a>srcs |  golang files to be linted   |  none |
| <a id="golangci_lint_action-config"></a>config |  label of the .golangci.yaml file   |  none |
| <a id="golangci_lint_action-report"></a>report |  output file to generate   |  none |
| <a id="golangci_lint_action-use_exit_code"></a>use_exit_code |  whether to fail the build when a lint violation is reported   |  <code>False</code> |


<a id="golangci_lint_aspect"></a>

## golangci_lint_aspect

<pre>
golangci_lint_aspect(<a href="#golangci_lint_aspect-binary">binary</a>, <a href="#golangci_lint_aspect-config">config</a>)
</pre>

A factory function to create a linter aspect.

Attrs:
    binary: a golangci-lint executable.
    config: the .golangci.yaml file

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="golangci_lint_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="golangci_lint_aspect-config"></a>config |  <p align="center"> - </p>   |  none |


