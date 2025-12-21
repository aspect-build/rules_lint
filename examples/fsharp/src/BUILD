load("@rules_dotnet//dotnet:defs.bzl", "fsharp_binary")

package(default_visibility = ["//visibility:public"])

fsharp_binary(
    name = "hello_fsharp",
    srcs = ["hello.fs"],
    target_frameworks = ["net9.0"],
)

filegroup(
    name = "all",
    srcs = [":hello_fsharp"],
)
