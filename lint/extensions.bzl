"Module extensions for use with bzlmod"

load("@aspect_tools_telemetry_report//:defs.bzl", "TELEMETRY")  # buildifier: disable=load
load("@bazel_features//:features.bzl", "bazel_features")

# buildifier: disable=bzl-visibility
load("@bazel_lib//lib/private:extension_utils.bzl", "extension_utils")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file", "http_jar")
load(
    "//tools/toolchains:register.bzl",
    "DEFAULT_SARIF_PARSER_REPOSITORY",
    "register_sarif_parser_toolchains",
)
load(":vale_library.bzl", "VALE_STYLE_DATA")

_tools = tag_class(attrs = {
    "cppcheck_linux": attr.string(),
    "cppcheck_macos": attr.string(),
    "spotbugs": attr.string(),
    "ktlint": attr.string(),
    "pmd": attr.string(),
    "checkstyle": attr.string(),
    "vale_styles": attr.string_list(),
})

def _public_build_file_content(line):
    return """package(default_visibility = ["//visibility:public"])\n{}\n""".format(line)

def _lint_extension_impl(mctx):
    for mod in mctx.modules:
        for tools in mod.tags.tools:
            # Download cppcheck premium tar files for different platforms
            # Even though cppcheckpremium is downloaded, it behaves like the free version, if we do not
            # provide a cppcheck.cfg file and license key.
            if tools.cppcheck_linux:
                http_archive(
                    name = tools.cppcheck_linux,
                    build_file_content = _public_build_file_content("""filegroup(name = "files", srcs = glob(["**"], exclude = ["cppcheck.cfg"]))"""),
                    integrity = "sha256-IqQ3Iofw6LoHh4YcdbN0m3tjg6utCiey7nGaOaPMv/I=",
                    strip_prefix = "cppcheckpremium-25.8.3",
                    urls = ["https://files.cppchecksolutions.com/25.8.3/ubuntu-22.04/cppcheckpremium-25.8.3-amd64.tar.gz"],
                )
            if tools.cppcheck_macos:
                http_archive(
                    name = tools.cppcheck_macos,
                    build_file_content = _public_build_file_content("""filegroup(name = "files", srcs = glob(["**"], exclude = ["cppcheck.cfg"]))"""),
                    integrity = "sha256-PEtm/DxKNZNJJuZE+56AZ80R22sZjZoziekAmR7FhNk=",
                    strip_prefix = "cppcheckpremium",
                    urls = ["https://files.cppchecksolutions.com/25.8.3/cppcheckpremium-25.8.3-macos-15.tar.gz"],
                )
            if tools.pmd:
                http_archive(
                    name = tools.pmd,
                    build_file_content = _public_build_file_content("""java_import(name = "{}", jars = glob(["*.jar"])""").format(tools.pmd),
                    integrity = "sha256-vov2j2wdZphL2WRak+Yxt4ocL0L18PhxkIL+rWdVOUA=",
                    strip_prefix = "pmd-bin-7.7.0/lib",
                    url = "https://github.com/pmd/pmd/releases/download/pmd_releases/7.7.0/pmd-dist-7.7.0-bin.zip",
                )
            if tools.checkstyle:
                http_jar(
                    name = tools.checkstyle,
                    url = "https://github.com/checkstyle/checkstyle/releases/download/checkstyle-10.17.0/checkstyle-10.17.0-all.jar",
                    sha256 = "51c34d738520c1389d71998a9ab0e6dabe0d7cf262149f3e01a7294496062e42",
                )
            if tools.ktlint:
                http_file(
                    name = tools.ktlint,
                    sha256 = "2e28cf46c27d38076bf63beeba0bdef6a845688d6c5dccd26505ce876094eb92",
                    url = "https://github.com/pinterest/ktlint/releases/download/1.2.1/ktlint",
                    executable = True,
                )
            if tools.spotbugs:
                http_archive(
                    name = tools.spotbugs,
                    integrity = "sha256-Z83FLM6xfq45T4/DZg8hZZzzVJCPgY5NH0Wmk1wuRCU=",
                    url = "https://github.com/spotbugs/spotbugs/releases/download/4.8.6/spotbugs-4.8.6.zip",
                    strip_prefix = "spotbugs-4.8.6",
                    build_file_content = _public_build_file_content("""java_import(name = "jar", jars = ["lib/spotbugs.jar"])"""),
                )
            for style_name in tools.vale_styles:
                styles = [s for s in VALE_STYLE_DATA if s["name"] == style_name]
                if not styles:
                    fail("Unknown Vale style: {}".format(style_name))
                style = styles[0]
                http_archive(
                    name = "vale_" + style["name"],
                    integrity = style["integrity"],
                    # Note: this is actually a directory, not a file
                    build_file_content = """exports_files(["{}"])""".format(style["name"]),
                    url = style["url"].format(style["version"]),
                )

lint = module_extension(
    implementation = _lint_extension_impl,
    tag_classes = {"tools": _tools},
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
