package(default_visibility = ["//visibility:public"])

filegroup(
    name = "bad",
    srcs = ["bad.toml"],
    tags = ["toml"],
)

filegroup(
    name = "hello",
    srcs = ["hello.toml"],
    tags = ["toml"],
)

filegroup(
    name = "all",
    srcs = [
        ":bad",
        ":hello",
    ],
)
