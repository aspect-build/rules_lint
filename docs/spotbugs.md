<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a spotbugs lint aspect that visits java_library and java_binary rules.

Typical usage:

First, call the `fetch_spotbugs` helper in `WORKSPACE` to download the jar file.
Alternatively you could use whatever you prefer for managing Java dependencies, such as a Maven integration rule.

Next, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
java_binary(
    name = "spotbugs",
    main_class = "edu.umd.cs.findbugs.LaunchAppropriateUI",
    runtime_deps = [
        "@spotbugs//:jar",
    ],
)
```

Finally, declare an aspect for it, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:spotbugs.bzl", "lint_spotbugs_aspect")

spotbugs = lint_spotbugs_aspect(
    binary = "@@//tools/lint:spotbugs",
    exclude_filter = "@@//:spotbugs-exclude.xml",
)

```

<a id="fetch_spotbugs"></a>

## fetch_spotbugs

<pre>
load("@aspect_rules_lint//lint:spotbugs.bzl", "fetch_spotbugs")

fetch_spotbugs()
</pre>





<a id="lint_spotbugs_aspect"></a>

## lint_spotbugs_aspect

<pre>
load("@aspect_rules_lint//lint:spotbugs.bzl", "lint_spotbugs_aspect")

lint_spotbugs_aspect(<a href="#lint_spotbugs_aspect-binary">binary</a>, <a href="#lint_spotbugs_aspect-exclude_filter">exclude_filter</a>, <a href="#lint_spotbugs_aspect-rule_kinds">rule_kinds</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_spotbugs_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="lint_spotbugs_aspect-exclude_filter"></a>exclude_filter |  <p align="center"> - </p>   |  none |
| <a id="lint_spotbugs_aspect-rule_kinds"></a>rule_kinds |  <p align="center"> - </p>   |  `["java_library", "java_binary"]` |


<a id="spotbugs_action"></a>

## spotbugs_action

<pre>
load("@aspect_rules_lint//lint:spotbugs.bzl", "spotbugs_action")

spotbugs_action(<a href="#spotbugs_action-ctx">ctx</a>, <a href="#spotbugs_action-executable">executable</a>, <a href="#spotbugs_action-srcs">srcs</a>, <a href="#spotbugs_action-exclude_filter">exclude_filter</a>, <a href="#spotbugs_action-stdout">stdout</a>, <a href="#spotbugs_action-exit_code">exit_code</a>, <a href="#spotbugs_action-options">options</a>)
</pre>

Run Spotbugs as an action under Bazel.

Based on https://spotbugs.readthedocs.io/en/latest/index.html


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="spotbugs_action-ctx"></a>ctx |  Bazel Rule or Aspect evaluation context   |  none |
| <a id="spotbugs_action-executable"></a>executable |  label of the the Spotbugs program   |  none |
| <a id="spotbugs_action-srcs"></a>srcs |  jar to be linted   |  none |
| <a id="spotbugs_action-exclude_filter"></a>exclude_filter |  label of the spotbugs-exclude.xml file   |  none |
| <a id="spotbugs_action-stdout"></a>stdout |  output file to generate   |  none |
| <a id="spotbugs_action-exit_code"></a>exit_code |  output file to write the exit code. If None, then fail the build when Spotbugs exits non-zero.   |  `None` |
| <a id="spotbugs_action-options"></a>options |  additional command-line options, see https://spotbugs.readthedocs.io/en/latest/running.html#command-line-options   |  `[]` |


