<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for calling declaring a buf lint aspect.

Typical usage:

```
load("@aspect_rules_lint//lint:buf.bzl", "buf_lint_aspect")

buf = buf_lint_aspect(
    config = "@@//path/to:buf.yaml",
)
```


<a id="buf_lint_action"></a>

## buf_lint_action

<pre>
buf_lint_action(<a href="#buf_lint_action-ctx">ctx</a>, <a href="#buf_lint_action-buf_toolchain">buf_toolchain</a>, <a href="#buf_lint_action-target">target</a>, <a href="#buf_lint_action-report">report</a>, <a href="#buf_lint_action-use_exit_code">use_exit_code</a>)
</pre>

Runs the buf lint tool as a Bazel action.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="buf_lint_action-ctx"></a>ctx |  Rule OR Aspect context   |  none |
| <a id="buf_lint_action-buf_toolchain"></a>buf_toolchain |  provides the buf-lint tool   |  none |
| <a id="buf_lint_action-target"></a>target |  the proto_library target to run on   |  none |
| <a id="buf_lint_action-report"></a>report |  output file to generate   |  none |
| <a id="buf_lint_action-use_exit_code"></a>use_exit_code |  whether the protoc process exiting non-zero will be a build failure   |  <code>False</code> |


<a id="buf_lint_aspect"></a>

## buf_lint_aspect

<pre>
buf_lint_aspect(<a href="#buf_lint_aspect-config">config</a>, <a href="#buf_lint_aspect-toolchain">toolchain</a>)
</pre>

A factory function to create a linter aspect.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="buf_lint_aspect-config"></a>config |  label of the the buf.yaml file   |  none |
| <a id="buf_lint_aspect-toolchain"></a>toolchain |  override the default toolchain of the protoc-gen-buf-lint tool   |  <code>"@rules_buf//tools/protoc-gen-buf-lint:toolchain_type"</code> |


