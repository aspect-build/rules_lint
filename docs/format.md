<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Produce a multi-formatter that aggregates formatter tools.

Some formatter tools may be installed by [multitool].
These are noted in the API docs below.

Note: Under `--enable_bzlmod`, rules_lint installs multitool automatically.
`WORKSPACE` users must install it manually; see the snippet on the releases page.

Other formatter binaries may be declared in your repository, typically in `tools/format/BUILD.bazel`.
You can test that they work by running them directly, with `bazel run -- //tools/format:some-tool`.
Then use the label `//tools/format:some-tool` as the value of whatever language attribute in `format_multirun`.
See the example/tools/format/BUILD file in this repo for full examples of declaring formatters.

[multitool]: https://registry.bazel.build/modules/rules_multitool

<a id="languages"></a>

## languages

<pre>
load("@aspect_rules_lint//format:defs.bzl", "languages")

languages(<a href="#languages-name">name</a>, <a href="#languages-c">c</a>, <a href="#languages-cc">cc</a>, <a href="#languages-css">css</a>, <a href="#languages-cuda">cuda</a>, <a href="#languages-gherkin">gherkin</a>, <a href="#languages-go">go</a>, <a href="#languages-graphql">graphql</a>, <a href="#languages-html">html</a>, <a href="#languages-java">java</a>, <a href="#languages-javascript">javascript</a>, <a href="#languages-jsonnet">jsonnet</a>, <a href="#languages-kotlin">kotlin</a>,
          <a href="#languages-markdown">markdown</a>, <a href="#languages-protocol_buffer">protocol_buffer</a>, <a href="#languages-python">python</a>, <a href="#languages-rust">rust</a>, <a href="#languages-scala">scala</a>, <a href="#languages-shell">shell</a>, <a href="#languages-sql">sql</a>, <a href="#languages-starlark">starlark</a>, <a href="#languages-swift">swift</a>, <a href="#languages-terraform">terraform</a>, <a href="#languages-xml">xml</a>,
          <a href="#languages-yaml">yaml</a>)
</pre>

Language attributes that may be passed to [format_multirun](#format_multirun) or [format_test](#format_test).

Files with matching extensions from [GitHub Linguist] will be formatted for the given language.

Some languages have dialects:
    - `javascript` includes TypeScript, TSX, and JSON.
    - `css` includes Less and Sass.

**Do not call the `languages` rule directly, it exists only to document the attributes.**

[GitHub Linguist]: https://github.com/github-linguist/linguist/blob/559a6426942abcae16b6d6b328147476432bf6cb/lib/linguist/languages.yml

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="languages-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="languages-c"></a>c |  a `clang-format` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-cc"></a>cc |  a `clang-format` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-css"></a>css |  a `prettier` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-cuda"></a>cuda |  a `clang-format` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-gherkin"></a>gherkin |  a `prettier` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-go"></a>go |  a `gofmt` binary, or any other tool that has a matching command-line interface. Use `@aspect_rules_lint//format:gofumpt` to choose the built-in tool.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-graphql"></a>graphql |  a `prettier` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-html"></a>html |  a `prettier` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-java"></a>java |  a `java-format` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-javascript"></a>javascript |  a `prettier` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-jsonnet"></a>jsonnet |  a `jsonnetfmt` binary, or any other tool that has a matching command-line interface. Use `@aspect_rules_lint//format:jsonnetfmt` to choose the built-in tool.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-kotlin"></a>kotlin |  a `ktfmt` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-markdown"></a>markdown |  a `prettier` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-protocol_buffer"></a>protocol_buffer |  a `buf` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-python"></a>python |  a `ruff` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-rust"></a>rust |  a `rustfmt` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-scala"></a>scala |  a `scalafmt` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-shell"></a>shell |  a `shfmt` binary, or any other tool that has a matching command-line interface. Use `@aspect_rules_lint//format:shfmt` to choose the built-in tool.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-sql"></a>sql |  a `prettier` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-starlark"></a>starlark |  a `buildifier` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-swift"></a>swift |  a `swiftformat` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-terraform"></a>terraform |  a `terraform-fmt` binary, or any other tool that has a matching command-line interface. Use `@aspect_rules_lint//format:terraform` to choose the built-in tool.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-xml"></a>xml |  a `prettier` binary, or any other tool that has a matching command-line interface.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="languages-yaml"></a>yaml |  a `yamlfmt` binary, or any other tool that has a matching command-line interface. Use `@aspect_rules_lint//format:yamlfmt` to choose the built-in tool.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |


<a id="format_multirun"></a>

## format_multirun

<pre>
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

format_multirun(<a href="#format_multirun-name">name</a>, <a href="#format_multirun-jobs">jobs</a>, <a href="#format_multirun-print_command">print_command</a>, <a href="#format_multirun-disable_git_attribute_checks">disable_git_attribute_checks</a>, <a href="#format_multirun-kwargs">kwargs</a>)
</pre>

Create a [multirun] binary for the given languages.

Intended to be used with `bazel run` to update source files in-place.

This macro produces a target named `[name].check` which does not edit files,
rather it exits non-zero if any sources require formatting.

To check formatting with `bazel test`, use [format_test](#format_test) instead.

[multirun]: https://registry.bazel.build/modules/rules_multirun


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="format_multirun-name"></a>name |  name of the resulting target, typically "format"   |  none |
| <a id="format_multirun-jobs"></a>jobs |  how many language formatters to spawn in parallel, ideally matching how many CPUs are available   |  `4` |
| <a id="format_multirun-print_command"></a>print_command |  whether to print a progress message before calling the formatter of each language. Note that a line is printed for a formatter even if no files of that language are to be formatted.   |  `False` |
| <a id="format_multirun-disable_git_attribute_checks"></a>disable_git_attribute_checks |  Set to True to disable honoring .gitattributes filters   |  `False` |
| <a id="format_multirun-kwargs"></a>kwargs |  attributes named for each language; see [languages](#languages)   |  none |


<a id="format_test"></a>

## format_test

<pre>
load("@aspect_rules_lint//format:defs.bzl", "format_test")

format_test(<a href="#format_test-name">name</a>, <a href="#format_test-srcs">srcs</a>, <a href="#format_test-workspace">workspace</a>, <a href="#format_test-no_sandbox">no_sandbox</a>, <a href="#format_test-disable_git_attribute_checks">disable_git_attribute_checks</a>, <a href="#format_test-tags">tags</a>, <a href="#format_test-kwargs">kwargs</a>)
</pre>

Create test for the given formatters.

Intended to be used with `bazel test` to verify files are formatted.
**This is not recommended**, because it is either non-hermetic or requires listing all source files.

To format with `bazel run`, see [format_multirun](#format_multirun).


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="format_test-name"></a>name |  name of the resulting target, typically "format"   |  none |
| <a id="format_test-srcs"></a>srcs |  list of files to verify formatting. Required when no_sandbox is False.   |  `None` |
| <a id="format_test-workspace"></a>workspace |  a file in the root directory to verify formatting. Required when no_sandbox is True. Typically `//:WORKSPACE` or `//:MODULE.bazel` may be used.   |  `None` |
| <a id="format_test-no_sandbox"></a>no_sandbox |  Set to True to enable formatting all files in the workspace. This mode causes the test to be non-hermetic and it cannot be cached. Read the documentation in /docs/formatting.md.   |  `False` |
| <a id="format_test-disable_git_attribute_checks"></a>disable_git_attribute_checks |  Set to True to disable honoring .gitattributes filters   |  `False` |
| <a id="format_test-tags"></a>tags |  tags to apply to generated targets. In 'no_sandbox' mode, `["no-sandbox", "no-cache", "external"]` are added to the tags.   |  `[]` |
| <a id="format_test-kwargs"></a>kwargs |  attributes named for each language; see [languages](#languages)   |  none |


