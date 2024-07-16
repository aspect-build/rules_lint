<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for calling declaring an ESLint lint aspect.

Typical usage:

First, install eslint using your typical npm package.json and rules_js rules.

Next, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
load("@npm//:eslint/package_json.bzl", eslint_bin = "bin")
eslint_bin.eslint_binary(name = "eslint")
```

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:eslint.bzl", "lint_eslint_aspect")

eslint = lint_eslint_aspect(
    binary = "@@//tools/lint:eslint",
    # We trust that eslint will locate the correct configuration file for a given source file.
    # See https://eslint.org/docs/latest/use/configure/configuration-files#cascading-and-hierarchy
    configs = [
        "@@//:eslintrc",
        ...
    ],
)
```

### With ts_project

Note, when used with `ts_project` and a custom `transpiler`,
the macro expands to several targets,
see https://github.com/aspect-build/rules_ts/blob/main/docs/transpiler.md#macro-expansion.

Since you want to lint the original TypeScript source files, the `ts_project` rule produced
by the macro is the one you want to lint, so when used with an `eslint_test` you should use
the `[name]_typings` label:

```
ts_project(
    name = "my_ts",
    transpiler = swc,
    ...
)

eslint_test(
    name = "lint_my_ts",
    srcs = [":my_ts_typings"],
)
```

See the [react example](https://github.com/bazelbuild/examples/blob/b498bb106b2028b531ceffbd10cc89530814a177/frontend/react/src/BUILD.bazel#L86-L92)


<a id="eslint_action"></a>

## eslint_action

<pre>
eslint_action(<a href="#eslint_action-ctx">ctx</a>, <a href="#eslint_action-executable">executable</a>, <a href="#eslint_action-srcs">srcs</a>, <a href="#eslint_action-stdout">stdout</a>, <a href="#eslint_action-exit_code">exit_code</a>, <a href="#eslint_action-format">format</a>, <a href="#eslint_action-env">env</a>)
</pre>

Create a Bazel Action that spawns an eslint process.

Adapter for wrapping Bazel around
https://eslint.org/docs/latest/use/command-line-interface


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="eslint_action-ctx"></a>ctx |  an action context OR aspect context   |  none |
| <a id="eslint_action-executable"></a>executable |  struct with an eslint field   |  none |
| <a id="eslint_action-srcs"></a>srcs |  list of file objects to lint   |  none |
| <a id="eslint_action-stdout"></a>stdout |  output file containing the stdout or --output-file of eslint   |  none |
| <a id="eslint_action-exit_code"></a>exit_code |  output file containing the exit code of eslint. If None, then fail the build when eslint exits non-zero.   |  <code>None</code> |
| <a id="eslint_action-format"></a>format |  value for eslint <code>--format</code> CLI flag   |  <code>None</code> |
| <a id="eslint_action-env"></a>env |  additional environment variables   |  <code>{}</code> |


<a id="eslint_fix"></a>

## eslint_fix

<pre>
eslint_fix(<a href="#eslint_fix-ctx">ctx</a>, <a href="#eslint_fix-executable">executable</a>, <a href="#eslint_fix-srcs">srcs</a>, <a href="#eslint_fix-patch">patch</a>, <a href="#eslint_fix-stdout">stdout</a>, <a href="#eslint_fix-exit_code">exit_code</a>)
</pre>

Create a Bazel Action that spawns eslint with --fix.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="eslint_fix-ctx"></a>ctx |  an action context OR aspect context   |  none |
| <a id="eslint_fix-executable"></a>executable |  struct with an eslint field   |  none |
| <a id="eslint_fix-srcs"></a>srcs |  list of file objects to lint   |  none |
| <a id="eslint_fix-patch"></a>patch |  output file containing the applied fixes that can be applied with the patch(1) command.   |  none |
| <a id="eslint_fix-stdout"></a>stdout |  output file containing the stdout or --output-file of eslint   |  none |
| <a id="eslint_fix-exit_code"></a>exit_code |  output file containing the exit code of eslint   |  none |


<a id="lint_eslint_aspect"></a>

## lint_eslint_aspect

<pre>
lint_eslint_aspect(<a href="#lint_eslint_aspect-binary">binary</a>, <a href="#lint_eslint_aspect-configs">configs</a>, <a href="#lint_eslint_aspect-rule_kinds">rule_kinds</a>)
</pre>

A factory function to create a linter aspect.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_eslint_aspect-binary"></a>binary |  the eslint binary, typically a rule like<br><br><pre><code> load("@npm//:eslint/package_json.bzl", eslint_bin = "bin") eslint_bin.eslint_binary(name = "eslint") </code></pre>   |  none |
| <a id="lint_eslint_aspect-configs"></a>configs |  label(s) of the eslint config file(s)   |  none |
| <a id="lint_eslint_aspect-rule_kinds"></a>rule_kinds |  which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect   |  <code>["js_library", "ts_project", "ts_project_rule"]</code> |


