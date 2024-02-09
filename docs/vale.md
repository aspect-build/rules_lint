<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for declaring a Vale lint aspect that visits markdown files.

First, all markdown sources must be the srcs of some Bazel rule.
Either use a `filegroup` with `markdown` in the `tags`:

```python
filegroup(
    name = "md",
    srcs = glob(["*.md"]),
    tags = ["markdown"],
)
```

or use a `markdown_library` rule such as the one in &lt;https://github.com/dwtj/dwtj_rules_markdown&gt;.
Aspect plans to provide support for Markdown in [configure]() so these rules can be automatically
maintained rather than requiring developers to write them by hand.

Note that any Markdown files in the repo which aren't in the `srcs` of one of these rules will *not*
be linted by Vale.

## Styles

Vale is powered by [Styles](https://vale.sh/docs/vale-cli/structure/#styles).
There is a [built-in style](https://vale.sh/docs/topics/styles/#built-in-style) and if this is
sufficient then it's not necessary to follow the rest of this section.

The styles from https://vale.sh/hub/ are already fetched by `fetch_vale()` which has a Bazel-based
mirror of https://github.com/errata-ai/packages/blob/master/library.json.
It's possible to fetch more styles using a typical `http_archive()` call.

At runtime, Vale requires the styles are "installed" into a folder together.
Use the [`copy_to_directory`](https://docs.aspect.build/rulesets/aspect_bazel_lib/docs/copy_to_directory/)
rule to accomplish this, for example,

```python
copy_to_directory(
    name = "vale_styles",
    srcs = ["@vale_write-good//:write-good"],
    include_external_repositories = ["vale_*"],
)
```

Now the `.vale.ini` file will have a `StylesPath` entry that points to this folder, for example,

```ini
StylesPath = tools/vale_styles
```

Finally, it's necessary for the `.vale.ini` file to be copied to the bazel-bin folder so that it
is relative to the generated `vale_styles` folder.
Use [`copy_to_bin`](https://docs.aspect.build/rulesets/aspect_bazel_lib/docs/copy_to_bin/) for this:

```starlark
copy_to_bin(
    name = ".vale_ini",
    srcs = [".vale.ini"],
)
```

See the example in rules_lint for a fully-working vale setup.

## Usage

```starlark
load("@aspect_rules_lint//lint:vale.bzl", "vale_aspect")

vale = vale_aspect(
    binary = "@@//tools:vale",
    # A copy_to_bin rule that places the .vale.ini file into bazel-bin
    config = "@@//:.vale_ini",
    # Optional.
    # A copy_to_directory rule that "installs" custom styles together into a single folder
    styles = "@@//tools:vale_styles",
)
```


<a id="fetch_vale"></a>

## fetch_vale

<pre>
fetch_vale(<a href="#fetch_vale-tag">tag</a>)
</pre>

A repository macro used from WORKSPACE to fetch vale binaries

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="fetch_vale-tag"></a>tag |  a tag of vale that we have mirrored, e.g. <code>v3.0.5</code>   |  <code>"v3.0.7"</code> |


<a id="vale_action"></a>

## vale_action

<pre>
vale_action(<a href="#vale_action-ctx">ctx</a>, <a href="#vale_action-executable">executable</a>, <a href="#vale_action-srcs">srcs</a>, <a href="#vale_action-styles">styles</a>, <a href="#vale_action-config">config</a>, <a href="#vale_action-report">report</a>, <a href="#vale_action-use_exit_code">use_exit_code</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="vale_action-ctx"></a>ctx |  <p align="center"> - </p>   |  none |
| <a id="vale_action-executable"></a>executable |  <p align="center"> - </p>   |  none |
| <a id="vale_action-srcs"></a>srcs |  <p align="center"> - </p>   |  none |
| <a id="vale_action-styles"></a>styles |  <p align="center"> - </p>   |  none |
| <a id="vale_action-config"></a>config |  <p align="center"> - </p>   |  none |
| <a id="vale_action-report"></a>report |  <p align="center"> - </p>   |  none |
| <a id="vale_action-use_exit_code"></a>use_exit_code |  <p align="center"> - </p>   |  <code>False</code> |


<a id="vale_aspect"></a>

## vale_aspect

<pre>
vale_aspect(<a href="#vale_aspect-binary">binary</a>, <a href="#vale_aspect-config">config</a>, <a href="#vale_aspect-styles">styles</a>)
</pre>

A factory function to create a linter aspect.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="vale_aspect-binary"></a>binary |  <p align="center"> - </p>   |  none |
| <a id="vale_aspect-config"></a>config |  <p align="center"> - </p>   |  none |
| <a id="vale_aspect-styles"></a>styles |  <p align="center"> - </p>   |  <code>Label("//lint:empty_styles")</code> |


