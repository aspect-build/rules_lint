"module extension to fetch formatter tools"

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file", "http_jar")

_tools = tag_class(attrs = {
    "taplo": attr.string(doc = "If set, fetches the Taplo formatter for TOML files to the given repository name."),
    "swiftformat_linux": attr.string(doc = "If true, fetches the SwiftFormat formatter for Swift files."),
    "swiftformat_macos": attr.string(doc = "If true, fetches the SwiftFormat formatter for Swift files."),
    "ktfmt": attr.string(doc = "If true, fetches the ktfmt formatter for Kotlin files."),
    "google_java_format": attr.string(doc = "If true, fetches the Google Java Format formatter for Java files."),
})

def _format_impl(module_ctx):
    for mod in module_ctx.modules:
        for tools in mod.tags.tools:
            if tools.taplo:
                http_file(
                    name = tools.taplo,
                    sha256 = "8fe196b894ccf9072f98d4e1013a180306e17d244830b03986ee5e8eabeb6156",
                    url = "https://github.com/tamasfe/taplo/releases/download/0.10.0/taplo-linux-x86_64.gz",
                )
            if tools.google_java_format:
                http_jar(
                    name = tools.google_java_format,
                    sha256 = "33068bbbdce1099982ec1171f5e202898eb35f2919cf486141e439fc6e3a4203",
                    url = "https://github.com/google/google-java-format/releases/download/v1.17.0/google-java-format-1.17.0-all-deps.jar",
                )
            if tools.ktfmt:
                http_jar(
                    name = tools.ktfmt,
                    integrity = "sha256-l/x/vRlNAan6RdgUfAVSQDAD1VusSridhNe7TV4/SN4=",
                    url = "https://repo1.maven.org/maven2/com/facebook/ktfmt/0.46/ktfmt-0.46-jar-with-dependencies.jar",
                )

            if tools.swiftformat_linux:
                http_archive(
                    name = tools.swiftformat_linux,
                    build_file_content = "filegroup(name = \"swiftformat\", srcs=[\"swiftformat_linux\"], visibility=[\"//visibility:public\"])",
                    patch_cmds = ["chmod u+x swiftformat_linux"],
                    sha256 = "f62813980c2848cb1941f1456a2a06251c2e2323183623760922058b98c70745",
                    url = "https://github.com/nicklockwood/SwiftFormat/releases/download/0.49.17/swiftformat_linux.zip",
                )
            if tools.swiftformat_macos:
                http_archive(
                    name = tools.swiftformat_macos,
                    build_file_content = "filegroup(name = \"swiftformat_mac\", srcs=[\"swiftformat\"], visibility=[\"//visibility:public\"])",
                    patch_cmds = [
                        # On MacOS, `xattr -c` clears the "Unknown developer" warning when executing a fetched binary
                        "if command -v xattr > /dev/null; then xattr -c swiftformat; fi",
                        "chmod u+x swiftformat",
                    ],
                    sha256 = "978eaffdc3716bbc0859aecee0d83875cf3ab8d8725779448f0035309d9ad9f3",
                    url = "https://github.com/nicklockwood/SwiftFormat/releases/download/0.49.17/swiftformat.zip",
                )

    return module_ctx.extension_metadata(reproducible = True)

# Define the module extension, making it available to other modules
format = module_extension(
    implementation = _format_impl,
    # Define the schema for tags that users can specify in MODULE.bazel
    tag_classes = {
        "tools": _tools,
    },
)
