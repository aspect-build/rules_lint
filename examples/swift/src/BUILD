package(default_visibility = ["//visibility:public"])

exports_files([
    "nested/.swiftlint.yml",
    "nested/deeper/.swiftlint.yml",
    "nested_fix/.swiftlint.yml",
])

filegroup(
    name = "lint",
    srcs = ["lintme.swift"],
    tags = ["swift"],
)

filegroup(
    name = "baseline",
    srcs = ["lintme.swift"],
    tags = ["swift-baseline"],
)

filegroup(
    name = "default_config",
    srcs = ["lintme.swift"],
    tags = ["swift-default-config"],
)

filegroup(
    name = "verbose",
    srcs = ["lintme.swift"],
    tags = ["swift-verbose"],
)

filegroup(
    name = "nested_config",
    srcs = ["nested/lintme.swift"],
    tags = ["swift-nested-config"],
)

filegroup(
    name = "nested_deeper_nearest_config",
    srcs = ["nested/deeper/nearest.swift"],
    tags = ["swift-nested-deeper-nearest-config"],
)

filegroup(
    name = "nested_without_declared_config",
    srcs = ["nested/lintme.swift"],
    tags = ["swift-nested-without-declared-config"],
)

filegroup(
    name = "nested_fix_config",
    srcs = ["nested_fix/lintme.swift"],
    tags = ["swift-nested-fix-config"],
)
