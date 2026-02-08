load("//tools/lint:linters.bzl", "yamllint_test")

package(default_visibility = ["//visibility:public"])

yamllint_test(
    name = "yamllint",
    srcs = ["//src:all"],
    expected_exit_code = 1,
)
