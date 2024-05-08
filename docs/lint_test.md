<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Factory function to make lint test rules.

When the linter exits non-zero, the test will print the output of the linter and then fail.

To use this, in your `linters.bzl` where you define the aspect, just create a test that references it.

For example, with `flake8`:

```starlark
load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")
load("@aspect_rules_lint//lint:flake8.bzl", "flake8_aspect")

flake8 = flake8_aspect(
    binary = "@@//:flake8",
    config = "@@//:.flake8",
)

flake8_test = lint_test(aspect = flake8)
```

Now in your BUILD files you can add a test:

```starlark
load("//tools/lint:linters.bzl", "flake8_test")

py_library(
    name = "unused_import",
    srcs = ["unused_import.py"],
)

flake8_test(
    name = "flake8",
    srcs = [":unused_import"],
)
```


<a id="lint_test"></a>

## lint_test

<pre>
lint_test(<a href="#lint_test-aspect">aspect</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_test-aspect"></a>aspect |  <p align="center"> - </p>   |  none |


