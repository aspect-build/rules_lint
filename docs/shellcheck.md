<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a shellcheck lint aspect that visits sh_{binary|library|test} rules.

Typical usage:

Shellcheck is provided as a built-in tool by rules_lint. To use the built-in version, first add a dependency on rules_multitool to MODULE.bazel:

```starlark
bazel_dep(name = "rules_multitool", version = <desired version>)

multitool = use_extension("@rules_multitool//multitool:extension.bzl", "multitool")
use_repo(multitool, "multitool")
```

Then create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:shellcheck.bzl", "lint_shellcheck_aspect")

shellcheck = lint_shellcheck_aspect(
    binary = "@multitool//tools/shellcheck",
    config = Label("//:.shellcheckrc"),
)
```

<a id="lint_shellcheck_aspect"></a>

## lint_shellcheck_aspect

<pre>
load("@aspect_rules_lint//lint:shellcheck.bzl", "lint_shellcheck_aspect")

lint_shellcheck_aspect(<a href="#lint_shellcheck_aspect-binary">binary</a>, <a href="#lint_shellcheck_aspect-config">config</a>, <a href="#lint_shellcheck_aspect-rule_kinds">rule_kinds</a>)
</pre>

A factory function to create a linter aspect.

Attrs:
    binary: a shellcheck executable.
    config: the .shellcheckrc file

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_shellcheck_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="lint_shellcheck_aspect-config"></a>config |  <p align="center"> - </p>   |  none |
| <a id="lint_shellcheck_aspect-rule_kinds"></a>rule_kinds |  <p align="center"> - </p>   |  `["sh_binary", "sh_library", "sh_test"]` |


<a id="shellcheck_action"></a>

## shellcheck_action

<pre>
load("@aspect_rules_lint//lint:shellcheck.bzl", "shellcheck_action")

shellcheck_action(<a href="#shellcheck_action-ctx">ctx</a>, <a href="#shellcheck_action-executable">executable</a>, <a href="#shellcheck_action-srcs">srcs</a>, <a href="#shellcheck_action-config">config</a>, <a href="#shellcheck_action-stdout">stdout</a>, <a href="#shellcheck_action-exit_code">exit_code</a>, <a href="#shellcheck_action-options">options</a>)
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
| <a id="shellcheck_action-stdout"></a>stdout |  output file containing stdout of shellcheck   |  none |
| <a id="shellcheck_action-exit_code"></a>exit_code |  output file containing shellcheck exit code. If None, then fail the build when vale exits non-zero. See https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md#return-values   |  `None` |
| <a id="shellcheck_action-options"></a>options |  additional command-line options, see https://github.com/koalaman/shellcheck/blob/master/shellcheck.hs#L95   |  `[]` |


