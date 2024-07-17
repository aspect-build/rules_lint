<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a PMD lint aspect that visits java_library rules.

Typical usage:

First, call the `fetch_pmd` helper in `WORKSPACE` to download the zip file.
Alternatively you could use whatever you prefer for managing Java dependencies, such as a Maven integration rule.

Next, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
java_binary(
    name = "pmd",
    main_class = "net.sourceforge.pmd.PMD",
    runtime_deps = ["@net_sourceforge_pmd"],
)
```

Finally, declare an aspect for it, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:pmd.bzl", "pmd_aspect")

pmd = pmd_aspect(
    binary = "@@//tools/lint:pmd",
    rulesets = ["@@//:pmd.xml"],
)
```


<a id="fetch_pmd"></a>

## fetch_pmd

<pre>
fetch_pmd()
</pre>





<a id="lint_pmd_aspect"></a>

## lint_pmd_aspect

<pre>
lint_pmd_aspect(<a href="#lint_pmd_aspect-binary">binary</a>, <a href="#lint_pmd_aspect-rulesets">rulesets</a>, <a href="#lint_pmd_aspect-rule_kinds">rule_kinds</a>)
</pre>

A factory function to create a linter aspect.

Attrs:
    binary: a PMD executable. Can be obtained from rules_java like so:

        ```
        java_binary(
            name = "pmd",
            main_class = "net.sourceforge.pmd.PMD",
            # Point to wherever you have the java_import rule defined, see our example
            runtime_deps = ["@net_sourceforge_pmd"],
        )
        ```

    rulesets: the PMD ruleset XML files

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_pmd_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="lint_pmd_aspect-rulesets"></a>rulesets |  <p align="center"> - </p>   |  none |
| <a id="lint_pmd_aspect-rule_kinds"></a>rule_kinds |  <p align="center"> - </p>   |  <code>["java_binary", "java_library"]</code> |


<a id="pmd_action"></a>

## pmd_action

<pre>
pmd_action(<a href="#pmd_action-ctx">ctx</a>, <a href="#pmd_action-executable">executable</a>, <a href="#pmd_action-srcs">srcs</a>, <a href="#pmd_action-rulesets">rulesets</a>, <a href="#pmd_action-stdout">stdout</a>, <a href="#pmd_action-exit_code">exit_code</a>, <a href="#pmd_action-options">options</a>)
</pre>

Run PMD as an action under Bazel.

Based on https://docs.pmd-code.org/latest/pmd_userdocs_installation.html#running-pmd-via-command-line


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="pmd_action-ctx"></a>ctx |  Bazel Rule or Aspect evaluation context   |  none |
| <a id="pmd_action-executable"></a>executable |  label of the the PMD program   |  none |
| <a id="pmd_action-srcs"></a>srcs |  java files to be linted   |  none |
| <a id="pmd_action-rulesets"></a>rulesets |  list of labels of the PMD ruleset files   |  none |
| <a id="pmd_action-stdout"></a>stdout |  output file to generate   |  none |
| <a id="pmd_action-exit_code"></a>exit_code |  output file to write the exit code. If None, then fail the build when PMD exits non-zero.   |  <code>None</code> |
| <a id="pmd_action-options"></a>options |  additional command-line options, see https://pmd.github.io/pmd/pmd_userdocs_cli_reference.html   |  <code>[]</code> |


