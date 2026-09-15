package(default_visibility = ["//visibility:public"])

exports_files(["nested/.sqlfluff"])

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
    name = "mixed_configs_with_target_data",
    srcs = [
        "clean.dml",
        "macro_query.sql.j2",
        "nested/lowercase.sql",
    ],
    data = [":jinja_data"],
    tags = ["lint-with-sqlfluff"],
)

filegroup(
    name = "template_without_data",
    srcs = ["macro_query.sql.j2"],
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
