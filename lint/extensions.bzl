"Module extensions for use with bzlmod"

load("@bazel_features//:features.bzl", "bazel_features")
load(
    "//tools/toolchains:register.bzl",
    "DEFAULT_SARIF_PARSER_REPOSITORY",
    "register_sarif_parser_toolchains",
)

def _toolchains_extension_impl(mctx):
    for mod in mctx.modules:
        for sarif_parser in mod.tags.sarif_parser:
            register_sarif_parser_toolchains(sarif_parser.name, register = False)

    if bazel_features.external_deps.extension_metadata_has_reproducible:
        return mctx.extension_metadata(reproducible = True)
    return mctx.extension_metadata()

toolchains = module_extension(
    implementation = _toolchains_extension_impl,
    tag_classes = {
        "sarif_parser": tag_class(attrs = {"name": attr.string(default = DEFAULT_SARIF_PARSER_REPOSITORY)}),
    },
)
