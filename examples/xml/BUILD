load("@aspect_rules_js//js:defs.bzl", "js_library")
load("@npm//:defs.bzl", "npm_link_all_packages")

package(default_visibility = ["//visibility:public"])

npm_link_all_packages(name = "node_modules")

js_library(
    name = "prettierrc",
    srcs = ["prettier.config.cjs"],
    deps = [
        ":node_modules/@prettier/plugin-xml",
    ],
)
