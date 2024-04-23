<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for calling declaring an ktlint lint aspect.

Typical usage:
Make sure you have `ktlint` pulled as a dependency into your WORKSPACE/module by pulling a version of it from here
https://github.com/pinterest/ktlint/releases and using a `http_file` declaration for it like.

```
http_file(
    name = "com_github_pinterest_ktlint",
    sha256 = "2e28cf46c27d38076bf63beeba0bdef6a845688d6c5dccd26505ce876094eb92",
    url = "https://github.com/pinterest/ktlint/releases/download/1.2.1/ktlint",
    executable = True,
)
```

Then, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:ktlint.bzl", "ktlint_aspect")

ktlint = ktlint_aspect(
    binary = "@@com_github_pinterest_ktlint//file",
    # rules can be enabled/disabled from with this file
    editorconfig = "@@//:.editorconfig",
    # a baseline file with exceptions for violations
    baseline_file = "@@//:.ktlint-baseline.xml",
)
```


<a id="fetch_ktlint"></a>

## fetch_ktlint

<pre>
fetch_ktlint()
</pre>





<a id="ktlint_action"></a>

## ktlint_action

<pre>
ktlint_action(<a href="#ktlint_action-ctx">ctx</a>, <a href="#ktlint_action-executable">executable</a>, <a href="#ktlint_action-srcs">srcs</a>, <a href="#ktlint_action-editorconfig">editorconfig</a>, <a href="#ktlint_action-report">report</a>, <a href="#ktlint_action-baseline_file">baseline_file</a>, <a href="#ktlint_action-java_runtime">java_runtime</a>,
              <a href="#ktlint_action-use_exit_code">use_exit_code</a>)
</pre>

 Runs ktlint as build action in Bazel.

Adapter for wrapping Bazel around
https://pinterest.github.io/ktlint/latest/install/cli/


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="ktlint_action-ctx"></a>ctx |  an action context or aspect context   |  none |
| <a id="ktlint_action-executable"></a>executable |  struct with ktlint field   |  none |
| <a id="ktlint_action-srcs"></a>srcs |  A list of source files to lint   |  none |
| <a id="ktlint_action-editorconfig"></a>editorconfig |  The file object pointing to the editorconfig file used by ktlint   |  none |
| <a id="ktlint_action-report"></a>report |  :output:  the stdout of ktlint containing any violations found   |  none |
| <a id="ktlint_action-baseline_file"></a>baseline_file |  The file object pointing to the baseline file used by ktlint.   |  none |
| <a id="ktlint_action-java_runtime"></a>java_runtime |  The Java Runtime configured for this build, pulled from the registered toolchain.   |  none |
| <a id="ktlint_action-use_exit_code"></a>use_exit_code |  whether a non-zero exit code from ktlint process will result in a build failure.   |  <code>False</code> |


<a id="lint_ktlint_aspect"></a>

## lint_ktlint_aspect

<pre>
lint_ktlint_aspect(<a href="#lint_ktlint_aspect-binary">binary</a>, <a href="#lint_ktlint_aspect-editorconfig">editorconfig</a>, <a href="#lint_ktlint_aspect-baseline_file">baseline_file</a>)
</pre>

A factory function to create a linter aspect.

Attrs:
    binary: a ktlint executable, provided as file typically through http_file declaration or using fetch_ktlint in your WORKSPACE.
    editorconfig: The label of the file pointing to the .editorconfig file used by ktlint.
    baseline_file: An optional attribute pointing to the label of the baseline file used by ktlint.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_ktlint_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="lint_ktlint_aspect-editorconfig"></a>editorconfig |  <p align="center"> - </p>   |  none |
| <a id="lint_ktlint_aspect-baseline_file"></a>baseline_file |  <p align="center"> - </p>   |  none |


