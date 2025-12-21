load("@rules_java//java:defs.bzl", "java_library")

package(default_visibility = ["//visibility:public"])

java_library(
    name = "foo",
    srcs = ["Foo.java"],
    deps = [":FooUtils"],
)

java_library(
    name = "FooUtils",
    srcs = ["FileReaderUtil.java"],
)

java_library(
    name = "bar",
    srcs = ["Bar.java"],
)
