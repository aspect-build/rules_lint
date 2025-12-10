"module extension to fetch formatter tools"

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file", "http_jar")

def _format_impl(module_ctx):
    for mod in module_ctx.modules:
        for r in mod.tags.taplo:
            http_file(
                name = r.name,
                sha256 = "8fe196b894ccf9072f98d4e1013a180306e17d244830b03986ee5e8eabeb6156",
                url = "https://github.com/tamasfe/taplo/releases/download/0.10.0/taplo-linux-x86_64.gz",
            )
        for r in mod.tags.google_java_format:
            http_jar(
                name = r.name,
                sha256 = "33068bbbdce1099982ec1171f5e202898eb35f2919cf486141e439fc6e3a4203",
                url = "https://github.com/google/google-java-format/releases/download/v1.17.0/google-java-format-1.17.0-all-deps.jar",
            )
        for r in mod.tags.ktfmt:
            http_jar(
                name = r.name,
                integrity = "sha256-l/x/vRlNAan6RdgUfAVSQDAD1VusSridhNe7TV4/SN4=",
                url = "https://repo1.maven.org/maven2/com/facebook/ktfmt/0.46/ktfmt-0.46-jar-with-dependencies.jar",
            )
        for r in mod.tags.swiftformat:
            http_archive(
                name = r.linux,
                build_file_content = "filegroup(name = \"swiftformat\", srcs=[\"swiftformat_linux\"], visibility=[\"//visibility:public\"])",
                patch_cmds = ["chmod u+x swiftformat_linux"],
                sha256 = "f62813980c2848cb1941f1456a2a06251c2e2323183623760922058b98c70745",
                url = "https://github.com/nicklockwood/SwiftFormat/releases/download/0.49.17/swiftformat_linux.zip",
            )
            http_archive(
                name = r.macos,
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
tools = module_extension(
    implementation = _format_impl,
    # Define the schema for tags that users can specify in MODULE.bazel
    tag_classes = {
        "google_java_format": tag_class(attrs = {"name": attr.string(default = "google-java-format")}),
        "taplo": tag_class(attrs = {"name": attr.string(default = "taplo")}),
        "ktfmt": tag_class(attrs = {"name": attr.string(default = "ktfmt")}),
        "swiftformat": tag_class(attrs = {"linux": attr.string(default = "swiftformat"), "macos": attr.string(default = "swiftformat_mac")}),
    },
)
