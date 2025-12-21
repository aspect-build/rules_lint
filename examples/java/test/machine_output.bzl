"Java-specific machine report rules for testing."

load("@aspect_rules_lint//lint:private/machine_report_testing.bzl", "_machine_report")
load("//tools/lint:linters.bzl", "checkstyle", "pmd", "spotbugs")

machine_pmd_report = rule(
    implementation = _machine_report,
    attrs = {"src": attr.label(aspects = [pmd])},
)

machine_checkstyle_report = rule(
    implementation = _machine_report,
    attrs = {"src": attr.label(aspects = [checkstyle])},
)

machine_spotbugs_report = rule(
    implementation = _machine_report,
    attrs = {"src": attr.label(aspects = [spotbugs])},
)
