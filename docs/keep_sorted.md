<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a keep-sorted lint aspect that visits all source files.

Typical usage:

First, fetch the keep-sorted dependency via gazelle

Then, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
go_deps = use_extension("@gazelle//:extensions.bzl", "go_deps")
go_deps.from_file(go_mod = "//:go.mod")
use_repo(go_deps, "com_github_google_keep_sorted")
```

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:keep_sorted.bzl", "lint_keep_sorted_aspect")


keep_sorted = lint_keep_sorted_aspect(
    binary = "@com_github_google_keep_sorted//:keep-sorted",
)
```

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


