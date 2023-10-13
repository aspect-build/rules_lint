<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for calling declaring an ESLint lint aspect.

Typical usage:

```
load("@aspect_rules_lint//lint:eslint.bzl", "eslint_aspect")

eslint = eslint_aspect(
    binary = "@@//path/to:eslint",
    config = "@@//path/to:eslintrc",
)
```


<a id="eslint_action"></a>

## eslint_action

<pre>
eslint_action(<a href="#eslint_action-ctx">ctx</a>, <a href="#eslint_action-executable">executable</a>, <a href="#eslint_action-srcs">srcs</a>, <a href="#eslint_action-report">report</a>, <a href="#eslint_action-use_exit_code">use_exit_code</a>)
</pre>

Create a Bazel Action that spawns an eslint process.

Adapter for wrapping Bazel around
https://eslint.org/docs/latest/use/command-line-interface


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="eslint_action-ctx"></a>ctx |  an action context OR aspect context   |  none |
| <a id="eslint_action-executable"></a>executable |  struct with an eslint field   |  none |
| <a id="eslint_action-srcs"></a>srcs |  list of file objects to lint   |  none |
| <a id="eslint_action-report"></a>report |  output to create   |  none |
| <a id="eslint_action-use_exit_code"></a>use_exit_code |  whether an eslint process exiting non-zero will be a build failure   |  <code>False</code> |


<a id="eslint_aspect"></a>

## eslint_aspect

<pre>
eslint_aspect(<a href="#eslint_aspect-binary">binary</a>, <a href="#eslint_aspect-config">config</a>)
</pre>

A factory function to create a linter aspect.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="eslint_aspect-binary"></a>binary |  the eslint binary, typically a rule like<br><br><pre><code> load("@npm//:eslint/package_json.bzl", eslint_bin = "bin") eslint_bin.eslint_binary(name = "eslint") </code></pre>   |  none |
| <a id="eslint_aspect-config"></a>config |  label of the eslint config file   |  none |


