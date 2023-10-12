<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for calling declaring an ESLint lint aspect.

Typical usage:

```
load("@aspect_rules_lint//lint:eslint.bzl", "eslint_aspect")

eslint = eslint_aspect(
    binary = "@@//path/to:eslint",
    config = "@@//path/to:eslintrc",
)
```


<a id="eslint_aspect"></a>

## eslint_aspect

<pre>
eslint_aspect(<a href="#eslint_aspect-binary">binary</a>, <a href="#eslint_aspect-config">config</a>)
</pre>

A factory function to create a linter aspect.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="eslint_aspect-binary"></a>binary |  the eslint binary, typically a rule like<br><br><pre><code> load("@npm//:eslint/package_json.bzl", eslint_bin = "bin") eslint_bin.eslint_binary(name = "eslint") </code></pre>   |  none |
| <a id="eslint_aspect-config"></a>config |  label of the eslint config file   |  none |


