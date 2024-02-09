"""API for declaring a Vale lint aspect that visits markdown files.

First, all markdown sources must be the srcs of some Bazel rule.
Either use a `filegroup` with `markdown` in the `tags`:

```python
filegroup(
    name = "md",
    srcs = glob(["*.md"]),
    tags = ["markdown"],
)
```

or use a `markdown_library` rule such as the one in <https://github.com/dwtj/dwtj_rules_markdown>.
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
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//lint/private:lint_aspect.bzl", "report_file")
load(":vale_library.bzl", "fetch_styles")
load(":vale_versions.bzl", "VALE_VERSIONS")

_MNEMONIC = "Vale"

# buildifier: disable=function-docstring
def vale_action(ctx, executable, srcs, styles, config, report, use_exit_code = False):
    # NB: Users must make sure the config file we reference is already in
    # bazel-out/arch/bin/my/pkg so that relative reference "tools/styles" correctly resolves
    # to the generated styles folder in bazel-out/arch/bin/my/pkg/tools/styles
    # We don't try to use copy_file_to_bin_action because the config file is likely not in the same
    # package as the aspect is visiting, so we won't be allowed to write to it and will just fail
    # in bazel-lib with _file_in_different_package_error_msg
    inputs = srcs + [config]
    if styles:
        inputs.append(styles)

    # Wire command-line options, see output of vale --help
    args = ctx.actions.args()
    args.add_all(srcs)
    args.add_all(["--config", config])
    args.add_all(["--output", "line"])

    if use_exit_code:
        command = "{vale} $@ && touch {report}"
    else:
        command = "{vale} $@ >{report} || true"

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [report],
        command = command.format(
            vale = executable.path,
            report = report.path,
        ),
        arguments = [args],
        mnemonic = _MNEMONIC,
        tools = [executable],
    )

# buildifier: disable=function-docstring
def _vale_aspect_impl(target, ctx):
    # There's no "official" markdown_library rule.
    # Users might want to try https://github.com/dwtj/dwtj_rules_markdown but we expect many won't
    # want to take that dependency.
    # So allow a filegroup(tags=["markdown"]) as an alternative rule to host the srcs.
    if ctx.rule.kind == "markdown_library" or (ctx.rule.kind == "filegroup" and "markdown" in ctx.rule.attr.tags):
        report, info = report_file(_MNEMONIC, target, ctx)
        styles = None
        if ctx.files._styles:
            if len(ctx.files._styles) != 1:
                fail("Only a single directory should be in styles")
            styles = ctx.files._styles[0]
            if not styles.is_directory:
                fail("Styles should be a directory containing installed styles")
        vale_action(ctx, ctx.executable._vale, ctx.rule.files.srcs, styles, ctx.file._config, report, ctx.attr.fail_on_violation)
        return [info]

    return []

def vale_aspect(binary, config, styles = Label("//lint:empty_styles")):
    """A factory function to create a linter aspect."""
    return aspect(
        implementation = _vale_aspect_impl,
        attrs = {
            "fail_on_violation": attr.bool(),
            "_vale": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config": attr.label(
                allow_single_file = True,
                mandatory = True,
                doc = "Config file",
                default = config,
            ),
            "_styles": attr.label(
                default = styles,
            ),
        },
    )

def fetch_vale(tag = VALE_VERSIONS.keys()[0]):
    """A repository macro used from WORKSPACE to fetch vale binaries

    Args:
        tag: a tag of vale that we have mirrored, e.g. `v3.0.5`
    """
    version = tag.lstrip("v")
    url = "https://github.com/errata-ai/vale/releases/download/{tag}/vale_{version}_{plat}.{ext}"

    for plat, sha256 in VALE_VERSIONS[tag].items():
        is_windows = plat.startswith("Windows")

        maybe(
            http_archive,
            name = "vale_" + plat,
            url = url.format(
                tag = tag,
                plat = plat,
                version = version,
                ext = "zip" if is_windows else "tar.gz",
            ),
            sha256 = sha256,
            build_file_content = """exports_files(["vale", "vale.exe"])""",
        )

        fetch_styles()
