load("@rules_rs//rs:rust_binary.bzl", "rust_binary")
load("@rules_rs//rs:rust_library.bzl", "rust_library")
load("@rules_rs//rs:rust_test.bzl", "rust_test")

package(default_visibility = ["//visibility:public"])

genrule(
    name = "generated_input",
    outs = ["generated_file"],
    cmd = "echo 'THIS IS GENERATED' > $@",
)

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

# If a rust_binary/rust_library depends on a input that is a generated
# file it will copy all the inputs to the Bazel bin folder.
# See: https://github.com/bazelbuild/rules_rust/blob/74bd3d15f33c6133c84bf4348225cbc7ac206f51/rust/private/utils.bzl#L857
#
# This is causes a problem with rules_lint when run with --fix
rust_binary(
    name = "ok_binary_with_generated_inputs",
    srcs = ["ok_binary.rs"],
    compile_data = [":generated_input"],
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
