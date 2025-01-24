<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a keep-sorted lint aspect that visits all source files.

Typical usage:

First, fetch the keep-sorted dependency via gazelle. We provide a convenient go.mod file.
To keep it isolated from your other go dependencies, we recommend adding to .bazelrc:

    common --experimental_isolated_extension_usages

Next add to MODULE.bazel:

    keep_sorted_deps = use_extension("@gazelle//:extensions.bzl", "go_deps", isolate = True)
    keep_sorted_deps.from_file(go_mod = "@aspect_rules_lint//lint/keep-sorted:go.mod")
    use_repo(keep_sorted_deps, "com_github_google_keep_sorted")

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:keep_sorted.bzl", "lint_keep_sorted_aspect")

keep_sorted = lint_keep_sorted_aspect(
    binary = "@com_github_google_keep_sorted//:keep-sorted",
)
```

Now you can add `// keep-sorted start` / `// keep-sorted end` lines to your library sources,
following the documentation at https://github.com/google/keep-sorted#usage.

<a id="keep_sorted_action"></a>

## keep_sorted_action

<pre>
load("@aspect_rules_lint//lint:keep_sorted.bzl", "keep_sorted_action")

keep_sorted_action(<a href="#keep_sorted_action-ctx">ctx</a>, <a href="#keep_sorted_action-executable">executable</a>, <a href="#keep_sorted_action-srcs">srcs</a>, <a href="#keep_sorted_action-stdout">stdout</a>, <a href="#keep_sorted_action-exit_code">exit_code</a>, <a href="#keep_sorted_action-options">options</a>)
</pre>

Run keep-sorted as an action under Bazel.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="keep_sorted_action-ctx"></a>ctx |  Bazel Rule or Aspect evaluation context   |  none |
| <a id="keep_sorted_action-executable"></a>executable |  label of the the keep-sorted program   |  none |
| <a id="keep_sorted_action-srcs"></a>srcs |  files to be linted   |  none |
| <a id="keep_sorted_action-stdout"></a>stdout |  output file containing stdout   |  none |
| <a id="keep_sorted_action-exit_code"></a>exit_code |  output file containing exit code If None, then fail the build when program exits non-zero.   |  `None` |
| <a id="keep_sorted_action-options"></a>options |  additional command-line options   |  `[]` |


<a id="keep_sorted_fix"></a>

## keep_sorted_fix

<pre>
load("@aspect_rules_lint//lint:keep_sorted.bzl", "keep_sorted_fix")

keep_sorted_fix(<a href="#keep_sorted_fix-ctx">ctx</a>, <a href="#keep_sorted_fix-executable">executable</a>, <a href="#keep_sorted_fix-srcs">srcs</a>, <a href="#keep_sorted_fix-patch">patch</a>, <a href="#keep_sorted_fix-stdout">stdout</a>, <a href="#keep_sorted_fix-exit_code">exit_code</a>, <a href="#keep_sorted_fix-options">options</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="keep_sorted_fix-ctx"></a>ctx |  <p align="center"> - </p>   |  none |
| <a id="keep_sorted_fix-executable"></a>executable |  <p align="center"> - </p>   |  none |
| <a id="keep_sorted_fix-srcs"></a>srcs |  <p align="center"> - </p>   |  none |
| <a id="keep_sorted_fix-patch"></a>patch |  <p align="center"> - </p>   |  none |
| <a id="keep_sorted_fix-stdout"></a>stdout |  <p align="center"> - </p>   |  none |
| <a id="keep_sorted_fix-exit_code"></a>exit_code |  <p align="center"> - </p>   |  `None` |
| <a id="keep_sorted_fix-options"></a>options |  <p align="center"> - </p>   |  `[]` |


<a id="lint_keep_sorted_aspect"></a>

## lint_keep_sorted_aspect

<pre>
load("@aspect_rules_lint//lint:keep_sorted.bzl", "lint_keep_sorted_aspect")

lint_keep_sorted_aspect(<a href="#lint_keep_sorted_aspect-binary">binary</a>)
</pre>

A factory function to create a linter aspect.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_keep_sorted_aspect-binary"></a>binary |  a keep-sorted executable   |  none |

**RETURNS**

An aspect definition for keep-sorted


