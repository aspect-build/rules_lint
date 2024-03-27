"""Support repos that aren't on bazel central registry.

Needed until Bazel 7 allows MODULE.bazel to directly call repository rules.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive", _http_file = "http_file", _http_jar = "http_jar")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def http_archive(**kwargs):
    maybe(_http_archive, **kwargs)

def http_file(**kwargs):
    maybe(_http_file, **kwargs)

def http_jar(**kwargs):
    maybe(_http_jar, **kwargs)

def rules_lint_dependencies():
    http_archive(
        name = "rules_multirun",
        sha256 = "0e124567fa85287874eff33a791c3bbdcc5343329a56faa828ef624380d4607c",
        url = "https://github.com/keith/rules_multirun/releases/download/0.9.0/rules_multirun.0.9.0.tar.gz",
    )

    http_archive(
        name = "rules_multitool",
        sha256 = "557b71b7d8d9975afc7fc2381c4c0e4220d43a581fb019217ca0a040d6cbebff",
        strip_prefix = "rules_multitool-0.6.0",
        url = "https://github.com/theoremlp/rules_multitool/releases/download/v0.6.0/rules_multitool-0.6.0.tar.gz",
    )

def fetch_pmd():
    http_archive(
        name = "net_sourceforge_pmd",
        build_file_content = """java_import(name = "net_sourceforge_pmd", jars = glob(["*.jar"]), visibility = ["//visibility:public"])""",
        sha256 = "21acf96d43cb40d591cacccc1c20a66fc796eaddf69ea61812594447bac7a11d",
        strip_prefix = "pmd-bin-6.55.0/lib",
        url = "https://github.com/pmd/pmd/releases/download/pmd_releases/6.55.0/pmd-bin-6.55.0.zip",
    )

def fetch_terraform():
    tf_version = "1.4.0"

    http_archive(
        name = "terraform_macos_aarch64",
        build_file_content = "exports_files([\"terraform\"])",
        sha256 = "d4a1e564714c6acf848e86dc020ff182477b49f932e3f550a5d9c8f5da7636fb",
        urls = ["https://releases.hashicorp.com/terraform/{0}/terraform_{0}_darwin_arm64.zip".format(tf_version)],
    )

    http_archive(
        name = "terraform_macos_x86_64",
        build_file_content = "exports_files([\"terraform\"])",
        sha256 = "e897a4217f1c3bfe37c694570dcc6371336fbda698790bb6b0547ec8daf1ffb3",
        urls = ["https://releases.hashicorp.com/terraform/{0}/terraform_{0}_darwin_amd64.zip".format(tf_version)],
    )

    http_archive(
        name = "terraform_linux_x86_64",
        build_file_content = "exports_files([\"terraform\"])",
        sha256 = "5da60da508d6d1941ffa8b9216147456a16bbff6db7622ae9ad01d314cbdd188",
        urls = ["https://releases.hashicorp.com/terraform/{0}/terraform_{0}_linux_amd64.zip".format(tf_version)],
    )

def fetch_java_format():
    http_jar(
        name = "google-java-format",
        sha256 = "33068bbbdce1099982ec1171f5e202898eb35f2919cf486141e439fc6e3a4203",
        url = "https://github.com/google/google-java-format/releases/download/v1.17.0/google-java-format-1.17.0-all-deps.jar",
    )

def fetch_ktfmt():
    http_jar(
        name = "ktfmt",
        integrity = "sha256-l/x/vRlNAan6RdgUfAVSQDAD1VusSridhNe7TV4/SN4=",
        url = "https://repo1.maven.org/maven2/com/facebook/ktfmt/0.46/ktfmt-0.46-jar-with-dependencies.jar",
    )

def fetch_swiftformat():
    # TODO: after https://github.com/bazelbuild/rules_swift/issues/864 we should only fetch for host
    http_archive(
        name = "swiftformat",
        build_file_content = "filegroup(name = \"swiftformat\", srcs=[\"swiftformat_linux\"], visibility=[\"//visibility:public\"])",
        patch_cmds = ["chmod u+x swiftformat_linux"],
        sha256 = "f62813980c2848cb1941f1456a2a06251c2e2323183623760922058b98c70745",
        url = "https://github.com/nicklockwood/SwiftFormat/releases/download/0.49.17/swiftformat_linux.zip",
    )

    http_archive(
        name = "swiftformat_mac",
        build_file_content = "filegroup(name = \"swiftformat_mac\", srcs=[\"swiftformat\"], visibility=[\"//visibility:public\"])",
        patch_cmds = [
            # On MacOS, `xattr -c` clears the "Unknown developer" warning when executing a fetched binary
            "if command -v xattr > /dev/null; then xattr -c swiftformat; fi",
            "chmod u+x swiftformat",
        ],
        sha256 = "978eaffdc3716bbc0859aecee0d83875cf3ab8d8725779448f0035309d9ad9f3",
        url = "https://github.com/nicklockwood/SwiftFormat/releases/download/0.49.17/swiftformat.zip",
    )
