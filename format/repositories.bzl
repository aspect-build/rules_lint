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
        sha256 = "ac97f3ab2869d1490130e68280366d4559510266a5b215c628c5afd4bd245d4e",
        strip_prefix = "rules_multitool-0.11.0",
        url = "https://github.com/theoremlp/rules_multitool/releases/download/v0.11.0/rules_multitool-0.11.0.tar.gz",
    )

    # Transitive of rules_multitool, included here for convenience
    # Note that many WORKSPACE users will get an earlier (and incompatible) version from some other *_dependencies() helper
    http_archive(
        name = "bazel_features",
        sha256 = "06f02b97b6badb3227df2141a4b4622272cdcd2951526f40a888ab5f43897f14",
        strip_prefix = "bazel_features-1.9.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.9.0/bazel_features-v1.9.0.tar.gz",
    )
