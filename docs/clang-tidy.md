<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for calling declaring a clang-tidy lint aspect.

Typical usage:

First, install clang-tidy with llvm_toolchain or as a native binary (llvm_toolchain
does not support Windows as of 06/2024, but providing a native clang-tidy.exe works)

Next, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

e.g. using llvm_toolchain:
```starlark
native_binary(
    name = "clang_tidy",
    src = "@llvm_toolchain_llvm//:bin/clang-tidy"
    out = "clang_tidy",
)
```

e.g as native binary:
```starlark
native_binary(
    name = "clang_tidy",
    src = "clang-tidy.exe"
    out = "clang_tidy",
)
```

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:clang_tidy.bzl", "clang_tidy_aspect")

clang_tidy = clang_tidy_aspect(
    binary = "@@//path/to:clang-tidy",
    configs = "@@//path/to:.clang-tidy",
)
```


<a id="clang_tidy_action"></a>

## clang_tidy_action

<pre>
clang_tidy_action(<a href="#clang_tidy_action-ctx">ctx</a>, <a href="#clang_tidy_action-compilation_context">compilation_context</a>, <a href="#clang_tidy_action-executable">executable</a>, <a href="#clang_tidy_action-srcs">srcs</a>, <a href="#clang_tidy_action-stdout">stdout</a>, <a href="#clang_tidy_action-exit_code">exit_code</a>)
</pre>

Create a Bazel Action that spawns a clang-tidy process.

Adapter for wrapping Bazel around
https://clang.llvm.org/extra/clang-tidy/


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="clang_tidy_action-ctx"></a>ctx |  an action context OR aspect context   |  none |
| <a id="clang_tidy_action-compilation_context"></a>compilation_context |  from target   |  none |
| <a id="clang_tidy_action-executable"></a>executable |  struct with a clang-tidy field   |  none |
| <a id="clang_tidy_action-srcs"></a>srcs |  file objects to lint   |  none |
| <a id="clang_tidy_action-stdout"></a>stdout |  <p align="center"> - </p>   |  none |
| <a id="clang_tidy_action-exit_code"></a>exit_code |  output file containing the exit code of clang-tidy. If None, then fail the build when clang-tidy exits non-zero.   |  none |


<a id="clang_tidy_fix"></a>

## clang_tidy_fix

<pre>
clang_tidy_fix(<a href="#clang_tidy_fix-ctx">ctx</a>, <a href="#clang_tidy_fix-compilation_context">compilation_context</a>, <a href="#clang_tidy_fix-executable">executable</a>, <a href="#clang_tidy_fix-srcs">srcs</a>, <a href="#clang_tidy_fix-patch">patch</a>, <a href="#clang_tidy_fix-stdout">stdout</a>, <a href="#clang_tidy_fix-exit_code">exit_code</a>)
</pre>

Create a Bazel Action that spawns clang-tidy with --fix.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="clang_tidy_fix-ctx"></a>ctx |  an action context OR aspect context   |  none |
| <a id="clang_tidy_fix-compilation_context"></a>compilation_context |  from target   |  none |
| <a id="clang_tidy_fix-executable"></a>executable |  struct with a clang_tidy field   |  none |
| <a id="clang_tidy_fix-srcs"></a>srcs |  list of file objects to lint   |  none |
| <a id="clang_tidy_fix-patch"></a>patch |  output file containing the applied fixes that can be applied with the patch(1) command.   |  none |
| <a id="clang_tidy_fix-stdout"></a>stdout |  output file containing the stdout or --output-file of clang-tidy   |  none |
| <a id="clang_tidy_fix-exit_code"></a>exit_code |  output file containing the exit code of clang-tidy   |  none |


<a id="lint_clang_tidy_aspect"></a>

## lint_clang_tidy_aspect

<pre>
lint_clang_tidy_aspect(<a href="#lint_clang_tidy_aspect-binary">binary</a>, <a href="#lint_clang_tidy_aspect-config">config</a>, <a href="#lint_clang_tidy_aspect-kwargs">kwargs</a>)
</pre>

A factory function to create a linter aspect.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_clang_tidy_aspect-binary"></a>binary |  the clang-tidy binary, typically a rule like<br><br><pre><code>starlark native_binary(     name = "clang_tidy",     src = "clang-tidy.exe"     out = "clang_tidy", ) </code></pre>   |  none |
| <a id="lint_clang_tidy_aspect-config"></a>config |  label of the .clang-tidy file   |  none |
| <a id="lint_clang_tidy_aspect-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


