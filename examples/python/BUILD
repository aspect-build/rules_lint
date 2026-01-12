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

# Update requirements.txt by running:
# bazel run //:requirements.update
pip_compile(
    name = "requirements",
    requirements_in = "pyproject.toml",
    requirements_txt = "requirements.txt",
)
