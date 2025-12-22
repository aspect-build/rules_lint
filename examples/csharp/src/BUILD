load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary")

package(default_visibility = ["//visibility:public"])

csharp_binary(
    name = "hello_csharp",
    srcs = ["hello.cs"],
    target_frameworks = ["net9.0"],
)

filegroup(
    name = "all",
    srcs = [":hello_csharp"],
)
