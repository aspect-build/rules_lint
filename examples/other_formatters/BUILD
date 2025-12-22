load("@aspect_rules_js//js:defs.bzl", "js_library")
load("@npm//:defs.bzl", "npm_link_all_packages")
load("@rules_python//python:pip.bzl", "compile_pip_requirements")

package(default_visibility = ["//visibility:public"])

compile_pip_requirements(
    name = "requirements",
    requirements_in = "requirements.in",
)

npm_link_all_packages(name = "node_modules")

js_library(
    name = "prettierrc",
    srcs = ["prettier.config.mjs"],
    deps = [
        ":node_modules/prettier-plugin-gherkin",
    ],
)
