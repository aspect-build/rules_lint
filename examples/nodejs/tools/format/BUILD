load("@aspect_rules_lint//format:defs.bzl", "format_multirun")
load("@npm//:@biomejs/biome/package_json.bzl", biome_bin = "bin")
load("@npm//:prettier/package_json.bzl", prettier = "bin")

package(default_visibility = ["//:__subpackages__"])

biome_bin.biome_binary(
    name = "biome",
    data = ["//:biomeconfig"],
    env = {"BAZEL_BINDIR": "."},
)

prettier.prettier_binary(
    name = "prettier",
    data = ["//:prettierrc"],
    env = {"BAZEL_BINDIR": "."},
    fixed_args = [
        "--config=\"$$JS_BINARY__RUNFILES\"/$(rlocationpath //:prettierrc)",
        "--loglevel=warn",
    ],
)

format_multirun(
    name = "format",
    css = ":prettier",  # css includes Less and SCSS
    html = ":prettier",
    javascript = ":prettier",
    markdown = ":prettier",
    visibility = ["//:__subpackages__"],
)

format_multirun(
    name = "format_biome",
    javascript = ":biome",
    javascript_check_args = ["format"],
    javascript_fix_args = ["format", "--write"],
    visibility = ["//:__subpackages__"],
)
