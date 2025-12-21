package(default_visibility = ["//visibility:public"])

filegroup(
    name = "all",
    srcs = ["config.yaml"],
    # Since this target isn't a yaml_library, we add a tag for the aspect to visit it.
    tags = ["lint-with-yamllint"],
)
