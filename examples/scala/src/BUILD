load("@rules_scala//scala:scala.bzl", "scala_binary", "scala_library")

package(default_visibility = ["//visibility:public"])

scala_library(
    name = "foo",
    srcs = ["Foo.scala"],
)

scala_binary(
    name = "App",
    srcs = ["App.scala"],
    main_class = "App",
    deps = [":foo"],
)
