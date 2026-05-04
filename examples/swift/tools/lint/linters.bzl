"Define Swift linter aspects"

load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")
load("@aspect_rules_lint//lint:swiftlint.bzl", "lint_swiftlint_aspect")

swiftlint = lint_swiftlint_aspect(
    binary = Label("//tools/lint:swiftlint"),
    configs = [Label("//:.swiftlint.yml")],
)

swiftlint_with_baseline = lint_swiftlint_aspect(
    binary = Label("//tools/lint:swiftlint"),
    configs = [Label("//:.swiftlint.yml")],
    baseline = Label("//:SwiftLintBaseline.json"),
    filegroup_tags = ["swift-baseline"],
)

swiftlint_default_config = lint_swiftlint_aspect(
    binary = Label("//tools/lint:swiftlint"),
    configs = [],
    filegroup_tags = ["swift-default-config"],
)

swiftlint_verbose = lint_swiftlint_aspect(
    binary = Label("//tools/lint:swiftlint"),
    configs = [Label("//:.swiftlint.yml")],
    filegroup_tags = ["swift-verbose"],
    quiet = False,
)

swiftlint_nested_config = lint_swiftlint_aspect(
    binary = Label("//tools/lint:swiftlint"),
    configs = [
        Label("//:.swiftlint.yml"),
        Label("//src:nested/.swiftlint.yml"),
    ],
    config_mode = "nested",
    filegroup_tags = ["swift-nested-config"],
)

swiftlint_nested_deeper_nearest_config = lint_swiftlint_aspect(
    binary = Label("//tools/lint:swiftlint"),
    configs = [
        Label("//:.swiftlint.yml"),
        Label("//src:nested/.swiftlint.yml"),
        Label("//src:nested/deeper/.swiftlint.yml"),
    ],
    config_mode = "nested",
    filegroup_tags = ["swift-nested-deeper-nearest-config"],
)

swiftlint_nested_without_declared_config = lint_swiftlint_aspect(
    binary = Label("//tools/lint:swiftlint"),
    configs = [Label("//:.swiftlint.yml")],
    config_mode = "nested",
    filegroup_tags = ["swift-nested-without-declared-config"],
)

swiftlint_nested_fix_config = lint_swiftlint_aspect(
    binary = Label("//tools/lint:swiftlint"),
    configs = [
        Label("//:.swiftlint.yml"),
        Label("//src:nested_fix/.swiftlint.yml"),
    ],
    config_mode = "nested",
    filegroup_tags = ["swift-nested-fix-config"],
)

swiftlint_test = lint_test(aspect = swiftlint)
swiftlint_baseline_test = lint_test(aspect = swiftlint_with_baseline)
swiftlint_default_config_test = lint_test(aspect = swiftlint_default_config)
swiftlint_nested_config_test = lint_test(aspect = swiftlint_nested_config)
swiftlint_nested_deeper_nearest_config_test = lint_test(aspect = swiftlint_nested_deeper_nearest_config)
swiftlint_nested_without_declared_config_test = lint_test(aspect = swiftlint_nested_without_declared_config)
