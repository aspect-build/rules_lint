load("@rules_scala//scala:scala.bzl", "scala_library")

package(default_visibility = ["//visibility:public"])

# Keep the filegroup for formatting example
filegroup(
    name = "all",
    srcs = ["hello.scala"],
)

# Scala library target for linting example
scala_library(
    name = "hello",
    srcs = ["hello.scala"],
)

# Scala library target for semantic linting example (unused imports)
scala_library(
    name = "semantic_test",
    srcs = ["semantic_test.scala"],
)
