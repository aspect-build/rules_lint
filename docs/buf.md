<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for calling declaring a buf lint aspect.

Typical usage:

```
load("@aspect_rules_lint//lint:buf.bzl", "buf_lint_aspect")

buf = buf_lint_aspect(
    config = "@@//path/to:buf.yaml",
)
```


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


