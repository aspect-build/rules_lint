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
buf_lint_action(<a href="#buf_lint_action-ctx">ctx</a>, <a href="#buf_lint_action-buf">buf</a>, <a href="#buf_lint_action-protoc">protoc</a>, <a href="#buf_lint_action-target">target</a>, <a href="#buf_lint_action-stderr">stderr</a>, <a href="#buf_lint_action-exit_code">exit_code</a>)
</pre>

Runs the buf lint tool as a Bazel action.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="buf_lint_action-ctx"></a>ctx |  Rule OR Aspect context   |  none |
| <a id="buf_lint_action-buf"></a>buf |  the buf-lint executable   |  none |
| <a id="buf_lint_action-protoc"></a>protoc |  the protoc executable   |  none |
| <a id="buf_lint_action-target"></a>target |  the proto_library target to run on   |  none |
| <a id="buf_lint_action-stderr"></a>stderr |  output file containing the stderr of protoc   |  none |
| <a id="buf_lint_action-exit_code"></a>exit_code |  output file to write the exit code. If None, then fail the build when protoc exits non-zero.   |  <code>None</code> |


<a id="lint_buf_aspect"></a>

## lint_buf_aspect

<pre>
lint_buf_aspect(<a href="#lint_buf_aspect-config">config</a>, <a href="#lint_buf_aspect-toolchain">toolchain</a>, <a href="#lint_buf_aspect-rule_kinds">rule_kinds</a>)
</pre>

A factory function to create a linter aspect.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_buf_aspect-config"></a>config |  label of the the buf.yaml file   |  none |
| <a id="lint_buf_aspect-toolchain"></a>toolchain |  override the default toolchain of the protoc-gen-buf-lint tool   |  <code>"@rules_buf//tools/protoc-gen-buf-lint:toolchain_type"</code> |
| <a id="lint_buf_aspect-rule_kinds"></a>rule_kinds |  which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect   |  <code>["proto_library"]</code> |


