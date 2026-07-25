package(default_visibility = ["//visibility:public"])

filegroup(
    name = "hello",
    srcs = ["hello.sql"],
    tags = ["lint-with-sqlfluff"],
)

filegroup(
    name = "query_template",
    srcs = ["query.sql.j2"],
    data = [":jinja_data"],
    tags = ["lint-with-sqlfluff"],
)

filegroup(
    name = "clean",
    srcs = ["clean.dml"],
    tags = ["lint-with-sqlfluff"],
)

filegroup(
    name = "jinja_data",
    srcs = ["templates/helpers.sql.j2"],
)

filegroup(
    name = "all",
    srcs = ["hello.sql"],
)
