<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for calling declaring an ktlint lint aspect.

Typical usage:

Firstly, make sure you're using `rules_jvm_external` to install your Maven dependencies and then add `com.pinterest.ktlint:ktlint-cli` with the linter version to `artifacts` in `maven_install`,
in your WORKSPACE or MODULE.bazel. Then create a `ktlint` binary target to be used in your linter as follows, typically in `tools/linters/BUILD.bazel`:

```
java_binary(
    name = "ktlint",
    main_class = "com.pinterest.ktlint.Main",
    runtime_deps = [
        "@maven//:com_pinterest_ktlint_ktlint_cli",
    ],
)
```

```

Then, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:ktlint.bzl", "ktlint_aspect")

ktlint = ktlint_aspect(
    binary = "@@//tools/linters:ktlint",
    # rules can be enabled/disabled from with this file
    editorconfig = "@@//:.editorconfig",
    # a baseline file with exceptions for violations
    baseline_file = "@@//:.ktlint-baseline.xml",
)
```


<a id="ktlint_action"></a>

## ktlint_action

<pre>
ktlint_action(<a href="#ktlint_action-ctx">ctx</a>, <a href="#ktlint_action-executable">executable</a>, <a href="#ktlint_action-srcs">srcs</a>, <a href="#ktlint_action-editorconfig">editorconfig</a>, <a href="#ktlint_action-report">report</a>, <a href="#ktlint_action-baseline_file">baseline_file</a>, <a href="#ktlint_action-use_exit_code">use_exit_code</a>)
</pre>

 Runs ktlint as build action in Bazel.

Adapter for wrapping Bazel around
https://pinterest.github.io/ktlint/latest/install/cli/


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="ktlint_action-ctx"></a>ctx |  an action context or aspect context   |  none |
| <a id="ktlint_action-executable"></a>executable |  struct with ktlint field   |  none |
| <a id="ktlint_action-srcs"></a>srcs |  A list of source files to lint   |  none |
| <a id="ktlint_action-editorconfig"></a>editorconfig |  The file object pointing to the editorconfig file used by ktlint   |  none |
| <a id="ktlint_action-report"></a>report |  :output:  the stdout of ktlint containing any violations found   |  none |
| <a id="ktlint_action-baseline_file"></a>baseline_file |  The file object pointing to the baseline file used by ktlint.   |  none |
| <a id="ktlint_action-use_exit_code"></a>use_exit_code |  whether a non-zero exit code from ktlint process will result in a build failure.   |  <code>False</code> |


<a id="lint_ktlint_aspect"></a>

## lint_ktlint_aspect

<pre>
lint_ktlint_aspect(<a href="#lint_ktlint_aspect-binary">binary</a>, <a href="#lint_ktlint_aspect-editorconfig">editorconfig</a>, <a href="#lint_ktlint_aspect-baseline_file">baseline_file</a>)
</pre>

A factory function to create a linter aspect.

Attrs:
    binary: a ktlint executable. This needs to be produced in your module/WORKSPACE as follows:

    Add a maven dependency on `com.pinterest.ktlint:ktlint-cli:&lt;version` using `maven_install` repository
    rule from rules_jvm_external
    WORKSPACE
        ```
        load("@rules_jvm_external//:defs.bzl", "maven_install")

        maven_install(
            artifacts = [
            ...
            "com.pinterest.ktlint:ktlint-cli:1.2.1",
            ],
            ...
        )
        ```

    MODULE.bazel
        ```
        maven = use_extension("@rules_jvm_external//:extensions.bzl", "maven")
        maven.install(
            artifacts = [
                ...
                "com.pinterest.ktlint:ktlint-cli:1.2.1"
            ],
            ...
        )
        ```

    Now declare a `java_binary` target that produces a ktlint executable using your Java toolchain, typically in `tools/linters/BUILD.bazel` as:

    ```
    java_binary(
        name = "ktlint",
        runtime_deps = [
            "@maven//:com_pinterest_ktlint_ktlint_cli"
        ],
        main_class = "com.pinterest.ktlint.Main"
    )
    ```

    editorconfig: The label of the file pointing to the .editorconfig file used by ktlint.
    baseline_file: An optional attribute pointing to the label of the baseline file used by ktlint.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_ktlint_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="lint_ktlint_aspect-editorconfig"></a>editorconfig |  <p align="center"> - </p>   |  none |
| <a id="lint_ktlint_aspect-baseline_file"></a>baseline_file |  <p align="center"> - </p>   |  none |


