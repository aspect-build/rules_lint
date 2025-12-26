load("@rules_uv//uv:pip.bzl", "pip_compile")

package(default_visibility = ["//visibility:public"])

exports_files(
    [
        ".pylintrc",
        ".flake8",
        "pyproject.toml",
    ],
    visibility = ["//visibility:public"],
)

pip_compile(
    name = "requirements",
    requirements_in = "pyproject.toml",
    requirements_txt = "requirements.txt",
)
