load("@rules_rust//rust:defs.bzl", "rust_binary", "rust_library", "rust_test")

package(default_visibility = ["//visibility:public"])

rust_library(
    name = "bad_lib",
    srcs = ["bad_lib.rs"],
    edition = "2021",
    visibility = [
        "//src:__pkg__",
        "//test:__pkg__",
        "//test/machine_outputs:__pkg__",
    ],
)

rust_library(
    name = "bad_lib_with_noclippy",
    srcs = ["bad_lib.rs"],
    edition = "2021",
    tags = ["noclippy"],
    visibility = [
        "//src:__pkg__",
        "//test:__pkg__",
    ],
)

rust_binary(
    name = "bad_binary",
    srcs = ["bad_binary.rs"],
    edition = "2021",
    visibility = [
        "//src:__pkg__",
        "//test:__pkg__",
    ],
)

rust_binary(
    name = "bad_binary_with_noclippy",
    srcs = ["bad_binary.rs"],
    edition = "2021",
    tags = ["noclippy"],
    visibility = [
        "//src:__pkg__",
        "//test:__pkg__",
    ],
)

rust_test(
    name = "bad_test",
    srcs = ["bad_test.rs"],
    edition = "2021",
    visibility = [
        "//test:__pkg__",
    ],
)

rust_binary(
    name = "ok_binary",
    srcs = ["ok_binary.rs"],
    edition = "2021",
    visibility = [
        "//src:__pkg__",
        "//test:__pkg__",
    ],
)

rust_binary(
    name = "ok_binary_with_bad_dep",
    srcs = ["ok_binary.rs"],
    edition = "2021",
    visibility = [
        "//src:__pkg__",
        "//test:__pkg__",
    ],
    deps = [":bad_lib"],
)

rust_binary(
    name = "ok_binary_with_bad_noclippy_dep",
    srcs = ["ok_binary.rs"],
    edition = "2021",
    visibility = [
        "//src:__pkg__",
        "//test:__pkg__",
    ],
    deps = [":bad_lib_with_noclippy"],
)

rust_test(
    name = "ok_test",
    srcs = ["ok_test.rs"],
    edition = "2021",
    visibility = [
        "//test:__pkg__",
    ],
)

rust_library(
    name = "warning_lib",
    srcs = ["warning_lib.rs"],
    edition = "2021",
    visibility = [
        "//src:__pkg__",
        "//test:__pkg__",
    ],
)

rust_binary(
    name = "ok_binary_with_warning_dep",
    srcs = ["ok_binary.rs"],
    edition = "2021",
    visibility = [
        "//src:__pkg__",
        "//test:__pkg__",
    ],
    deps = [":warning_lib"],
)

rust_binary(
    name = "binary_with_warning_and_error",
    srcs = ["warning_and_error.rs"],
    edition = "2021",
    visibility = [
        "//src/rust:__pkg__",
        "//test:__pkg__",
        "//test/machine_outputs:__pkg__",
    ],
)
