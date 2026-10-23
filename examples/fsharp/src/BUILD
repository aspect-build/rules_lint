load("@rules_dotnet//dotnet:defs.bzl", "fsharp_binary", "fsharp_library")

package(default_visibility = ["//visibility:public"])

fsharp_binary(
    name = "hello_fsharp",
    srcs = ["hello.fs"],
    target_frameworks = ["net9.0"],
)

fsharp_library(
    name = "record",
    srcs = ["record.fs"],
    target_frameworks = ["net9.0"],
)

filegroup(
    name = "all",
    srcs = [
        ":hello_fsharp",
        ":record",
    ],
)
