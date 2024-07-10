<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a tfsec lint aspect that visits filegroup rules.

Typical usage:

Use [tfsec_aspect](#tfsec_aspect) to declare the tfsec linter aspect, typically in in `tools/lint/linters.bzl`:

```
load("@aspect_rules_lint//lint:tfsec.bzl", "tfsec_aspect")

tfsec = tfsec_aspect(
    binary = "@multitool//tools/tfsec",
)
```

Note that tfsec has noted they are migrating its abilities to [Trivy](https://github.com/aquasecurity/trivy).


<a id="tfsec_aspect"></a>

## tfsec_aspect

<pre>
tfsec_aspect(<a href="#tfsec_aspect-binary">binary</a>, <a href="#tfsec_aspect-filegroup_tags">filegroup_tags</a>)
</pre>

A factory function to create a linter aspect.

Attrs:
    binary: a tfsec executable
    filegroup_tags: which tags on filegroups should be visited by the aspect

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="tfsec_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="tfsec_aspect-filegroup_tags"></a>filegroup_tags |  <p align="center"> - </p>   |  <code>["terraform", "scan-with-tfsec"]</code> |


