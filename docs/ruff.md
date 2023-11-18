<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a Ruff lint aspect that visits py_library rules.

Typical usage:

```
load("@aspect_rules_lint//lint:ruff.bzl", "ruff_aspect")

ruff = ruff_aspect(
    binary = "@@//:ruff",
    config = "@@//:.ruff.toml",
)
```


<a id="fetch_ruff"></a>

## fetch_ruff

<pre>
fetch_ruff(<a href="#fetch_ruff-version">version</a>)
</pre>

A repository macro used from WORKSPACE to fetch ruff binaries

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="fetch_ruff-version"></a>version |  a version of ruff that we have mirrored, e.g. <code>v0.1.0</code>   |  <code>"v0.1.6"</code> |


<a id="ruff_action"></a>

## ruff_action

<pre>
ruff_action(<a href="#ruff_action-ctx">ctx</a>, <a href="#ruff_action-executable">executable</a>, <a href="#ruff_action-srcs">srcs</a>, <a href="#ruff_action-config">config</a>, <a href="#ruff_action-report">report</a>, <a href="#ruff_action-use_exit_code">use_exit_code</a>)
</pre>

Run ruff as an action under Bazel.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="ruff_action-ctx"></a>ctx |  Bazel Rule or Aspect evaluation context   |  none |
| <a id="ruff_action-executable"></a>executable |  label of the the ruff program   |  none |
| <a id="ruff_action-srcs"></a>srcs |  python files to be linted   |  none |
| <a id="ruff_action-config"></a>config |  label of the ruff config file (pyproject.toml, ruff.toml, or .ruff.toml)   |  none |
| <a id="ruff_action-report"></a>report |  output file to generate   |  none |
| <a id="ruff_action-use_exit_code"></a>use_exit_code |  whether to fail the build when a lint violation is reported   |  <code>False</code> |


<a id="ruff_aspect"></a>

## ruff_aspect

<pre>
ruff_aspect(<a href="#ruff_aspect-binary">binary</a>, <a href="#ruff_aspect-config">config</a>)
</pre>

A factory function to create a linter aspect.

Attrs:
    binary: a ruff executable. Can be obtained like so:

        load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

        http_archive(
            name = "ruff_bin_linux_amd64",
            sha256 = "&lt;-sha-&gt;",
            urls = [
                "https://github.com/charliermarsh/ruff/releases/download/v&lt;-version-&gt;/ruff-x86_64-unknown-linux-gnu.tar.gz",
            ],
            build_file_content = """exports_files(["ruff"])""",
        )

    config: the ruff config file (`pyproject.toml`, `ruff.toml`, or `.ruff.toml`)

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="ruff_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="ruff_aspect-config"></a>config |  <p align="center"> - </p>   |  none |


