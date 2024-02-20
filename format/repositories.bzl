"""Support repos that aren't on bazel central registry.

Needed until Bazel 7 allows MODULE.bazel to directly call repository rules.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive", _http_file = "http_file", _http_jar = "http_jar")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def http_archive(name, **kwargs):
    maybe(_http_archive, name = name, **kwargs)

def http_file(name, **kwargs):
    maybe(_http_file, name = name, **kwargs)

def http_jar(name, **kwargs):
    maybe(_http_jar, name = name, **kwargs)

def fetch_pmd():
    http_archive(
        name = "net_sourceforge_pmd",
        build_file_content = """java_import(name = "net_sourceforge_pmd", jars = glob(["*.jar"]), visibility = ["//visibility:public"])""",
        sha256 = "21acf96d43cb40d591cacccc1c20a66fc796eaddf69ea61812594447bac7a11d",
        strip_prefix = "pmd-bin-6.55.0/lib",
        url = "https://github.com/pmd/pmd/releases/download/pmd_releases/6.55.0/pmd-bin-6.55.0.zip",
    )

# buildifier: disable=function-docstring
def fetch_jsonnet():
    jsonnet_version = "0.20.0"

    http_archive(
        name = "jsonnet_macos_aarch64",
        build_file_content = "exports_files([\"jsonnetfmt\"])",
        sha256 = "a15a699a58eb172c6d91f4cbddf3681095a649008628e0cfd84f564db4244ee3",
        urls = ["https://github.com/google/go-jsonnet/releases/download/v{0}/go-jsonnet_{0}_Darwin_arm64.tar.gz".format(jsonnet_version)],
    )

    http_archive(
        name = "jsonnet_macos_x86_64",
        build_file_content = "exports_files([\"jsonnetfmt\"])",
        sha256 = "76901637f60589bb9bf91b3481d4aecbc31efcd35ca99ae72bcb510b00270ad9",
        urls = ["https://github.com/google/go-jsonnet/releases/download/v{0}/go-jsonnet_{0}_Darwin_x86_64.tar.gz".format(jsonnet_version)],
    )

    http_archive(
        name = "jsonnet_linux_x86_64",
        build_file_content = "exports_files([\"jsonnetfmt\"])",
        sha256 = "a137c5e969609c3995c4d05817a247cfef8a92760c5306c3ad7df0355dd62970",
        urls = ["https://github.com/google/go-jsonnet/releases/download/v{0}/go-jsonnet_{0}_Linux_x86_64.tar.gz".format(jsonnet_version)],
    )

    http_archive(
        name = "jsonnet_linux_aarch64",
        build_file_content = "exports_files([\"jsonnetfmt\"])",
        sha256 = "49fbc99c91dcd2be53fa856307de3b8708c91dc5c74740714fdf9317957322e0",
        urls = ["https://github.com/google/go-jsonnet/releases/download/v{0}/go-jsonnet_{0}_Linux_arm64.tar.gz".format(jsonnet_version)],
    )

# buildifier: disable=function-docstring
def fetch_shfmt():
    shfmt_version = "3.8.0"

    http_file(
        name = "shfmt_darwin_x86_64",
        downloaded_file_path = "shfmt",
        executable = True,
        sha256 = "c0218b47a0301bb006f49fad85d2c08de23df303472834faf5639d04121320f8",
        urls = ["https://github.com/mvdan/sh/releases/download/v{0}/shfmt_v{0}_darwin_amd64".format(shfmt_version)],
    )

    http_file(
        name = "shfmt_darwin_aarch64",
        downloaded_file_path = "shfmt",
        executable = True,
        sha256 = "1481240d2a90d4f0b530688d76d4f9117d17a756b6027cfa42b96f0707317f83",
        urls = ["https://github.com/mvdan/sh/releases/download/v{0}/shfmt_v{0}_darwin_arm64".format(shfmt_version)],
    )

    http_file(
        name = "shfmt_linux_x86_64",
        downloaded_file_path = "shfmt",
        executable = True,
        sha256 = "27b3c6f9d9592fc5b4856c341d1ff2c88856709b9e76469313642a1d7b558fe0",
        urls = ["https://github.com/mvdan/sh/releases/download/v{0}/shfmt_v{0}_linux_amd64".format(shfmt_version)],
    )

    http_file(
        name = "shfmt_linux_aarch64",
        downloaded_file_path = "shfmt",
        executable = True,
        sha256 = "27e1f69b0d57c584bcbf5c882b4c4f78ffcf945d0efef45c1fbfc6692213c7c3",
        urls = ["https://github.com/mvdan/sh/releases/download/v{0}/shfmt_v{0}_linux_arm64".format(shfmt_version)],
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

def fetch_gofumpt():
    http_file(
        name = "com_github_mvdan_gofumpt_linux_amd64",
        downloaded_file_path = "gofumpt",
        executable = True,
        sha256 = "759c6ab56bfbf62cafb35944aef1e0104a117e0aebfe44816fd79ef4b28521e4",
        urls = [
            "https://cdn.confidential.cloud/constellation/cas/sha256/759c6ab56bfbf62cafb35944aef1e0104a117e0aebfe44816fd79ef4b28521e4",
            "https://github.com/mvdan/gofumpt/releases/download/v0.5.0/gofumpt_v0.5.0_linux_amd64",
        ],
    )

    http_file(
        name = "com_github_mvdan_gofumpt_linux_arm64",
        downloaded_file_path = "gofumpt",
        executable = True,
        sha256 = "fba20ffd06606c89a500e3cc836408a09e4767e2f117c97724237ae4ecadf82e",
        urls = [
            "https://cdn.confidential.cloud/constellation/cas/sha256/fba20ffd06606c89a500e3cc836408a09e4767e2f117c97724237ae4ecadf82e",
            "https://github.com/mvdan/gofumpt/releases/download/v0.5.0/gofumpt_v0.5.0_linux_arm64",
        ],
    )

    http_file(
        name = "com_github_mvdan_gofumpt_darwin_amd64",
        downloaded_file_path = "gofumpt",
        executable = True,
        sha256 = "870f05a23541aad3d20d208a3ea17606169a240f608ac1cf987426198c14b2ed",
        urls = [
            "https://cdn.confidential.cloud/constellation/cas/sha256/870f05a23541aad3d20d208a3ea17606169a240f608ac1cf987426198c14b2ed",
            "https://github.com/mvdan/gofumpt/releases/download/v0.5.0/gofumpt_v0.5.0_darwin_amd64",
        ],
    )

    http_file(
        name = "com_github_mvdan_gofumpt_darwin_arm64",
        downloaded_file_path = "gofumpt",
        executable = True,
        sha256 = "f2df95d5fad8498ad8eeb0be8abdb8bb8d05e8130b332cb69751dfd090fabac4",
        urls = [
            "https://cdn.confidential.cloud/constellation/cas/sha256/f2df95d5fad8498ad8eeb0be8abdb8bb8d05e8130b332cb69751dfd090fabac4",
            "https://github.com/mvdan/gofumpt/releases/download/v0.5.0/gofumpt_v0.5.0_darwin_arm64",
        ],
    )

# From https://github.com/google/yamlfmt/releases/download/v0.11.0/checksums.txt
_yamlfmt_shas = {
    "8211a9e15f6abfc0bfad621414d3aeeac0d4b6bf4e6b8781fb19fb016c2740b7": "yamlfmt_0.11.0_Darwin_arm64.tar.gz",
    "76aaa47bb4778fbd83113453c569c46272c608d9a416f73a237822c78d686af2": "yamlfmt_0.11.0_Darwin_x86_64.tar.gz",
    "76da015f98e34f29216eab8b6155e419c0a2b623c466e997299ad5c225207992": "yamlfmt_0.11.0_Linux_arm64.tar.gz",
    "8d58cc5baffda8fd3ad0da110c85e93f597403210686d9d3af0bb26ee21519c5": "yamlfmt_0.11.0_Linux_i386.tar.gz",
    "8579868c3fbb0deca2573586e07d9912b5f07a302fb2bf26dac10791328c9998": "yamlfmt_0.11.0_Linux_x86_64.tar.gz",
    "9ab6e2ad02118daf5f2d570268eba98837a5350e141539f0f844c4f8eed5d2ea": "yamlfmt_0.11.0_Windows_arm64.tar.gz",
    "9d2598d90cfcdadb61b9843fb446af72a6ce7e7778ef4682c9a40411b746c3ef": "yamlfmt_0.11.0_Windows_i386.tar.gz",
    "ca2327f2fb842b42b0607b4e7da7a85d87380dc8625aad955819c40bed1882e8": "yamlfmt_0.11.0_Windows_x86_64.tar.gz",
}

def fetch_yamlfmt():
    for sha256, filename in _yamlfmt_shas.items():
        reponame = filename.removesuffix(".tar.gz").replace("0.11.0_", "")
        http_archive(
            name = reponame,
            build_file_content = "exports_files([\"yamlfmt\"])",
            sha256 = sha256,
            urls = ["https://github.com/google/yamlfmt/releases/download/v0.11.0/{}".format(filename)],
        )
