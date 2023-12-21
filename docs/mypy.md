<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a mypy lint aspect that visits py_library rules.

Typical usage:

```
load("@aspect_rules_lint//lint:mypy.bzl", "mypy_aspect")

mypy = mypy_aspect(
    binary = "@@//:mypy",
    configs = "@@//:pyproject.toml",
)
```

Optional: enable it in `.bazelrc`:

```
# Add mypy type-check validation actions to py_library targets.
# Disable for a particular build with --norun_validations
build --aspects=//tools:lint.bzl%mypy
```

### Reporting

Unlike most linters hosted in rules_lint, mypy produces only error semantics.
That means that typecheck violations will result in failed build actions, rather than
a report of warnings which can be handled in various ways.
See https://github.com/aspect-build/rules_lint/blob/main/docs/linting.md

However, it reports the violations using Bazel's Validation Actions feature, which means
you can pass the `--norun_validations` flag to skip type-checking for a particular build.

### Acknowledgements

This code inspired from https://github.com/bazel-contrib/bazel-mypy-integration
Thanks to the [contributors](https://github.com/bazel-contrib/bazel-mypy-integration/graphs/contributors)
especially [Jonathon Belotti](https://github.com/thundergolfer) and [David Zbarsky](https://github.com/dzbarsky).

### TODO

- Set the working directory when executing mypy so it selects the right configuration file:
  https://mypy.readthedocs.io/en/stable/config_file.html
- Support mypy plugins and show example.
- Allow configured typeshed repo, e.g. args.add("--custom-typeshed-dir", "external/my_typeshed")
- Avoid invalidating caches whenever mypy.ini changes
- Remote cache: bootstrap the stdlib since it will remain in cache, making other actions slightly faster
- Later: Generate `.pyi` outputs: optimization to avoid as much invalidation
  when only implementation bodies change, at the cost of an extra mypy action.


<a id="MypyInfo"></a>

## MypyInfo

<pre>
MypyInfo(<a href="#MypyInfo-transitive_cache_map">transitive_cache_map</a>)
</pre>

Python typechecking data

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="MypyInfo-transitive_cache_map"></a>transitive_cache_map |  depset: transitive --cache-map json files produced by deps    |


<a id="mypy_action"></a>

## mypy_action

<pre>
mypy_action(<a href="#mypy_action-ctx">ctx</a>, <a href="#mypy_action-executable">executable</a>, <a href="#mypy_action-srcs">srcs</a>, <a href="#mypy_action-deps">deps</a>, <a href="#mypy_action-configs">configs</a>)
</pre>

Run mypy as an action under Bazel.

See https://mypy.readthedocs.io/en/stable/command_line.html


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="mypy_action-ctx"></a>ctx |  Bazel Rule or Aspect evaluation context   |  none |
| <a id="mypy_action-executable"></a>executable |  label of the the mypy program   |  none |
| <a id="mypy_action-srcs"></a>srcs |  python files to be linted   |  none |
| <a id="mypy_action-deps"></a>deps |  the deps of the py_library or py_binary so mypy can read dependent types   |  none |
| <a id="mypy_action-configs"></a>configs |  label(s) of mypy config file(s)   |  none |

**RETURNS**

Providers, including a MypyInfo provider to propagate data to dependents and a Validation output group


<a id="mypy_aspect"></a>

## mypy_aspect

<pre>
mypy_aspect(<a href="#mypy_aspect-binary">binary</a>, <a href="#mypy_aspect-configs">configs</a>)
</pre>

A factory function to create a linter aspect.

Attrs:
    binary: a mypy executable
    configs: mypy config file(s) such as mypy.ini or pyproject.toml, see
        https://mypy.readthedocs.io/en/stable/config_file.html#config-file

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="mypy_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="mypy_aspect-configs"></a>configs |  <p align="center"> - </p>   |  none |


<a id="mypy_info"></a>

## mypy_info

<pre>
mypy_info(<a href="#mypy_info-direct">direct</a>, <a href="#mypy_info-deps">deps</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="mypy_info-direct"></a>direct |  <p align="center"> - </p>   |  none |
| <a id="mypy_info-deps"></a>deps |  <p align="center"> - </p>   |  none |


