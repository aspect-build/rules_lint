<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Factory function to make lint test rules.

The test will fail when the linter reports any non-empty lint results.

To use this, in your `lint.bzl` where you define the aspect, just create a test that references it.

For example, with `flake8`:

```starlark
load("@aspect_rules_lint//lint:assert_no_lint_warnings.bzl", "assert_no_lint_warnings")
load("@aspect_rules_lint//lint:flake8.bzl", "flake8_aspect")

flake8 = flake8_aspect(
    binary = "@@//:flake8",
    config = "@@//:.flake8",
)

flake8_test = assert_no_lint_warnings(aspect = flake8)
```

Now in your BUILD files you can add a test:

```starlark
load("//tools:lint.bzl", "flake8_test")

py_library(
    name = "unused_import",
    srcs = ["unused_import.py"],
)

flake8_test(
    name = "flake8",
    srcs = [":unused_import"],
)
```


<a id="assert_no_lint_warnings"></a>

## assert_no_lint_warnings

<pre>
assert_no_lint_warnings(<a href="#assert_no_lint_warnings-aspect">aspect</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="assert_no_lint_warnings-aspect"></a>aspect |  <p align="center"> - </p>   |  none |


