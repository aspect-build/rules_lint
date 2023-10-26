<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a shellcheck lint aspect that visits sh_library rules.

Typical usage:

1. Use [fetch_shellcheck](#fetch_shellcheck) in WORKSPACE to call the `http_archive` calls to download binaries.
2. Use [shellcheck_binary](#shellcheck_binary) in `tools/BUILD.bazel` to declare the shellcheck target
3. Use [shellcheck_aspect](#shellcheck_aspect) in `tools/lint.bzl` to declare the shellcheck linter aspect:

```
load("@aspect_rules_lint//lint:shellcheck.bzl", "shellcheck_aspect")

shellcheck = shellcheck_aspect(
    binary = "@@//tools:shellcheck",
    config = "@@//:.shellcheckrc",
)
```


<a id="fetch_shellcheck"></a>

## fetch_shellcheck

<pre>
fetch_shellcheck(<a href="#fetch_shellcheck-version">version</a>)
</pre>

A repository macro used from WORKSPACE to fetch binaries

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="fetch_shellcheck-version"></a>version |  a version of shellcheck that we have mirrored, e.g. <code>v0.9.0</code>   |  <code>"v0.9.0"</code> |


<a id="shellcheck_action"></a>

## shellcheck_action

<pre>
shellcheck_action(<a href="#shellcheck_action-ctx">ctx</a>, <a href="#shellcheck_action-executable">executable</a>, <a href="#shellcheck_action-srcs">srcs</a>, <a href="#shellcheck_action-config">config</a>, <a href="#shellcheck_action-report">report</a>, <a href="#shellcheck_action-use_exit_code">use_exit_code</a>)
</pre>

Run shellcheck as an action under Bazel.

Based on https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="shellcheck_action-ctx"></a>ctx |  Bazel Rule or Aspect evaluation context   |  none |
| <a id="shellcheck_action-executable"></a>executable |  label of the the shellcheck program   |  none |
| <a id="shellcheck_action-srcs"></a>srcs |  bash files to be linted   |  none |
| <a id="shellcheck_action-config"></a>config |  label of the .shellcheckrc file   |  none |
| <a id="shellcheck_action-report"></a>report |  output file to generate   |  none |
| <a id="shellcheck_action-use_exit_code"></a>use_exit_code |  whether to fail the build when a lint violation is reported   |  <code>False</code> |


<a id="shellcheck_aspect"></a>

## shellcheck_aspect

<pre>
shellcheck_aspect(<a href="#shellcheck_aspect-binary">binary</a>, <a href="#shellcheck_aspect-config">config</a>)
</pre>

A factory function to create a linter aspect.

Attrs:
    binary: a shellcheck executable.
    config: the .shellcheckrc file

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="shellcheck_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="shellcheck_aspect-config"></a>config |  <p align="center"> - </p>   |  none |


<a id="shellcheck_binary"></a>

## shellcheck_binary

<pre>
shellcheck_binary(<a href="#shellcheck_binary-name">name</a>)
</pre>

Wrapper around native_binary to select the correct shellcheck executable for the execution platform.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="shellcheck_binary-name"></a>name |  <p align="center"> - </p>   |  none |


