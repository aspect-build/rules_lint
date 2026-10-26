load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

package(default_visibility = ["//:__subpackages__"])

format_multirun(
    name = "format",
    c = "@llvm_toolchain_llvm//:bin/clang-format",
    cc = "@llvm_toolchain_llvm//:bin/clang-format",
    cuda = "@llvm_toolchain_llvm//:bin/clang-format",
    # clang-format writes only the files it is given, so it may run as parallel
    # batches.
    parallel = [
        "c",
        "cc",
        "cuda",
    ],
    visibility = ["//:__subpackages__"],
)
