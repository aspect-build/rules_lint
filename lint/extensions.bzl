"Module extensions for use with bzlmod"

# buildifier: disable=bzl-visibility
load("@aspect_bazel_lib//lib/private:extension_utils.bzl", "extension_utils")
load("@aspect_tools_telemetry_report//:defs.bzl", "TELEMETRY")  # buildifier: disable=load
load("@bazel_features//:features.bzl", "bazel_features")
load(
    "//tools/toolchains:register.bzl",
    "DEFAULT_SARIF_PARSER_REPOSITORY",
    "register_sarif_parser_toolchains",
)

def _toolchains_extension_impl(mctx):
    extension_utils.toolchain_repos_bfs(
        mctx = mctx,
        get_tag_fn = lambda tags: tags.sarif_parser,
        toolchain_name = "sarif_parser",
        toolchain_repos_fn = lambda name, version: register_sarif_parser_toolchains(name = name, register = False),
        get_version_fn = lambda attr: None,
    )

    if bazel_features.external_deps.extension_metadata_has_reproducible:
        return mctx.extension_metadata(reproducible = True)
    return mctx.extension_metadata()

toolchains = module_extension(
    implementation = _toolchains_extension_impl,
    tag_classes = {
        "sarif_parser": tag_class(attrs = {"name": attr.string(default = DEFAULT_SARIF_PARSER_REPOSITORY)}),
    },
)
