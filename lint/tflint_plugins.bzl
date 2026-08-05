"""Repository rule and module extension for fetching tflint plugin binaries.

tflint does not have a lockfile mechanism for plugins, so this rule uses Bazel
as the lockfile: each plugin version and its per-platform sha256 digests are
declared in `MODULE.bazel`, and Bazel fetches them hermetically.

## Usage with bzlmod

In your `MODULE.bazel`:

```starlark
tflint_plugins = use_extension("@aspect_rules_lint//lint:tflint_plugins.bzl", "tflint_ext")
tflint_plugins.plugin(
    name = "tflint_plugin_google",
    ruleset_name = "google",
    sha256s = {
        "linux_amd64": "abc123...",
        "linux_arm64": "def456...",
        "darwin_amd64": "789abc...",
        "darwin_arm64": "012def...",
    },
    url_template = "https://github.com/terraform-linters/tflint-ruleset-google/releases/download/v0.39.0/tflint-ruleset-google_{platform}.zip",
)
use_repo(tflint_plugins, "tflint_plugin_google")
```

Then pass the plugin to your aspect definition:

```starlark
tflint = lint_tflint_aspect(
    binary = "@aspect_rules_lint//lint:tflint_bin",
    plugins = [Label("@tflint_plugin_google//:plugin")],
)
```
"""

_PLATFORMS = {
    "linux_amd64": "@platforms//os:linux",
    "linux_arm64": "@platforms//os:linux",
    "darwin_amd64": "@platforms//os:macos",
    "darwin_arm64": "@platforms//os:macos",
}

_CPU = {
    "linux_amd64": "@platforms//cpu:x86_64",
    "linux_arm64": "@platforms//cpu:aarch64",
    "darwin_amd64": "@platforms//cpu:x86_64",
    "darwin_arm64": "@platforms//cpu:aarch64",
}

def _tflint_plugin_impl(rctx):
    name = rctx.attr.ruleset_name
    binary_name = "tflint-ruleset-{}".format(name)

    for platform, sha256 in rctx.attr.sha256s.items():
        if platform not in _PLATFORMS:
            fail("Unknown platform '{}'. Supported: {}".format(platform, ", ".join(_PLATFORMS.keys())))
        url = rctx.attr.url_template.format(platform = platform)
        rctx.download_and_extract(
            url = url,
            sha256 = sha256,
            output = platform,
        )

    # Generate a BUILD file with select() to pick the right platform binary.
    lines = [
        'package(default_visibility = ["//visibility:public"])',
        "",
        "alias(",
        '    name = "plugin",',
        "    actual = select({",
    ]
    for platform in rctx.attr.sha256s:
        target_name = platform.replace("/", "_")
        lines.append('        ":{}_condition": ":{}_bin",'.format(target_name, target_name))
    lines.append('        "//conditions:default": ":unsupported",')
    lines.append("    }),")
    lines.append(")")
    lines.append("")

    # Fallback for unsupported platforms.
    lines.append("filegroup(")
    lines.append('    name = "unsupported",')
    lines.append("    srcs = [],")
    lines.append('    tags = ["manual"],')
    lines.append(")")
    lines.append("")

    for platform in rctx.attr.sha256s:
        target_name = platform.replace("/", "_")
        os_constraint = _PLATFORMS[platform]
        cpu_constraint = _CPU[platform]

        lines.append("config_setting(")
        lines.append('    name = "{}_condition",'.format(target_name))
        lines.append("    constraint_values = [")
        lines.append('        "{}",'.format(os_constraint))
        lines.append('        "{}",'.format(cpu_constraint))
        lines.append("    ],")
        lines.append(")")
        lines.append("")

        lines.append("filegroup(")
        lines.append('    name = "{}_bin",'.format(target_name))
        lines.append('    srcs = ["{}/{}"],'.format(platform, binary_name))
        lines.append(")")
        lines.append("")

    rctx.file("BUILD.bazel", "\n".join(lines))

tflint_plugin = repository_rule(
    implementation = _tflint_plugin_impl,
    doc = """Fetches a tflint plugin for all declared platforms.

Each platform's binary is downloaded and extracted into its own directory.
A `select()`-based alias named `:plugin` resolves to the correct binary for
the current execution platform.
""",
    attrs = {
        "ruleset_name": attr.string(
            mandatory = True,
            doc = "Plugin name, e.g. 'google' for tflint-ruleset-google.",
        ),
        "url_template": attr.string(
            mandatory = True,
            doc = "URL template with a `{platform}` placeholder, e.g. " +
                  "`https://github.com/terraform-linters/tflint-ruleset-google/releases/download/v0.39.0/tflint-ruleset-google_{platform}.zip`.",
        ),
        "sha256s": attr.string_dict(
            mandatory = True,
            doc = "Map of platform key (e.g. `linux_amd64`) to sha256 of the archive.",
        ),
    },
)

def _tflint_ext_impl(mctx):
    for mod in mctx.modules:
        for plugin in mod.tags.plugin:
            tflint_plugin(
                name = plugin.name,
                ruleset_name = plugin.ruleset_name,
                url_template = plugin.url_template,
                sha256s = plugin.sha256s,
            )

_plugin_tag = tag_class(
    doc = "Declares a tflint plugin to fetch.",
    attrs = {
        "name": attr.string(mandatory = True, doc = "Repository name for this plugin."),
        "ruleset_name": attr.string(mandatory = True, doc = "Plugin name, e.g. 'google'."),
        "url_template": attr.string(mandatory = True, doc = "URL template with `{platform}` placeholder."),
        "sha256s": attr.string_dict(mandatory = True, doc = "Platform-to-sha256 map."),
    },
)

tflint_ext = module_extension(
    implementation = _tflint_ext_impl,
    tag_classes = {"plugin": _plugin_tag},
)
