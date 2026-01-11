load("@jq.bzl//jq:jq.bzl", "jq_test")
load("//test:machine_output.bzl", "machine_clippy_report")
load("//tools/lint:linters.bzl", "clippy_test")

package(default_visibility = ["//visibility:public"])

clippy_test(
    name = "clippy_ok_binary",
    srcs = ["//src:ok_binary"],
)

clippy_test(
    name = "clippy_ok_binary_with_bad_dep",
    srcs = ["//src:ok_binary_with_bad_dep"],
    # Expected to fail based on current content of the file.
    # Normally you'd fix the file instead of tagging this test.
    tags = ["manual"],
)

clippy_test(
    name = "clippy_ok_binary_with_bad_noclippy_dep",
    srcs = ["//src:ok_binary_with_bad_noclippy_dep"],
)

clippy_test(
    name = "clippy_bad_binary",
    srcs = ["//src:bad_binary"],
    # Expected to fail based on current content of the file.
    # Normally you'd fix the file instead of tagging this test.
    tags = ["manual"],
)

clippy_test(
    name = "clippy_bad_binary_noclippy",
    srcs = ["//src:bad_binary_with_noclippy"],
)

clippy_test(
    name = "clippy_bad_library",
    srcs = ["//src:bad_lib"],
    # Expected to fail based on current content of the file.
    # Normally you'd fix the file instead of tagging this test.
    tags = ["manual"],
)

clippy_test(
    name = "clippy_binary_with_warning_and_error",
    srcs = ["//src:binary_with_warning_and_error"],
    # Expected to fail based on current content of the file.
    # Normally you'd fix the file instead of tagging this test.
    tags = ["manual"],
)

machine_clippy_report(
    name = "machine_clippy_report",
    src = "//src:bad_lib",
)

# Because the json file from clippy contains multiple messages _not_ in an array, we must take the first element.
jq_test(
    name = "clippy_machine_output_test",
    file1 = ":machine_clippy_report",
    file2 = ":machine_clippy_report",
    filter1 = "inputs | first | .code.code",
    filter2 = "inputs | first | \"dead_code\"",
)
