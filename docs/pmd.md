<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a PMD lint aspect that visits java_library rules.

Typical usage:

```
load("@aspect_rules_lint//lint:pmd.bzl", "pmd_aspect")

pmd = pmd_aspect(
    binary = "@@//:PMD",
    # config = "@@//:.PMD",
)
```


<a id="lint_pmd_aspect"></a>

## lint_pmd_aspect

<pre>
lint_pmd_aspect(<a href="#lint_pmd_aspect-binary">binary</a>, <a href="#lint_pmd_aspect-rulesets">rulesets</a>)
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


<a id="pmd_action"></a>

## pmd_action

<pre>
pmd_action(<a href="#pmd_action-ctx">ctx</a>, <a href="#pmd_action-executable">executable</a>, <a href="#pmd_action-srcs">srcs</a>, <a href="#pmd_action-rulesets">rulesets</a>, <a href="#pmd_action-report">report</a>, <a href="#pmd_action-use_exit_code">use_exit_code</a>)
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
| <a id="pmd_action-report"></a>report |  output file to generate   |  none |
| <a id="pmd_action-use_exit_code"></a>use_exit_code |  whether to fail the build when a lint violation is reported   |  <code>False</code> |


