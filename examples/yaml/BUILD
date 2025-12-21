load("@rules_python//python:pip.bzl", "compile_pip_requirements")

package(default_visibility = ["//visibility:public"])

compile_pip_requirements(
    name = "requirements",
    requirements_in = "requirements.in",
)

exports_files(
    [".yamllint"],
    visibility = ["//visibility:public"],
)
