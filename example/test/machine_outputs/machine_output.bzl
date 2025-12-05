"Extracts the machine-readable SARIF report from a target that has been linted with rules_lint."

load("@bazel_features//:features.bzl", "bazel_features")
load("@jq.bzl//jq:jq.bzl", "jq_test")
load("//tools/lint:linters.bzl", "buf", "clang_tidy", "clippy", "eslint", "flake8", "pylint", "ruff", "shellcheck", "stylelint", "vale", "yamllint")

SARIF_TOOL_DRIVER_NAME_FILTER = ".runs[].tool.driver.name"
PHYSICAL_ARTIFACT_LOCATION_URI_FILTER = ".runs[].results | map(.locations | map(.physicalLocation.artifactLocation.uri)) | flatten | unique[]"

def report_test(name, report, expected_tool, expected_uri):
    # WORKSPACE only works with releases, not prerelease
    if not bazel_features.external_deps.is_bzlmod_enabled:
        return
    jq_test(
        name = name,
        file1 = report,
        file2 = report,
        filter1 = SARIF_TOOL_DRIVER_NAME_FILTER,
        filter2 = "\"%s\"" % expected_tool,
    )
    jq_test(
        name = name + ".uri",
        file1 = report,
        file2 = report,
        filter1 = PHYSICAL_ARTIFACT_LOCATION_URI_FILTER,
        filter2 = "\"%s\"" % expected_uri,
    )

def _machine_report(ctx):
    files = ctx.attr.src[OutputGroupInfo].rules_lint_machine.to_list()
    return [DefaultInfo(files = depset([r for r in files if r.path.endswith(".report")]))]

machine_ruff_report = rule(
    implementation = _machine_report,
    attrs = {"src": attr.label(aspects = [ruff])},
)

machine_shellcheck_report = rule(
    implementation = _machine_report,
    attrs = {"src": attr.label(aspects = [shellcheck])},
)

machine_eslint_report = rule(
    implementation = _machine_report,
    attrs = {"src": attr.label(aspects = [eslint])},
)

machine_stylelint_report = rule(
    implementation = _machine_report,
    attrs = {"src": attr.label(aspects = [stylelint])},
)

machine_vale_report = rule(
    implementation = _machine_report,
    attrs = {"src": attr.label(aspects = [vale])},
)

machine_clang_tidy_report = rule(
    implementation = _machine_report,
    attrs = {"src": attr.label(aspects = [clang_tidy])},
)

machine_buf_report = rule(
    implementation = _machine_report,
    attrs = {"src": attr.label(aspects = [buf])},
)

machine_flake8_report = rule(
    implementation = _machine_report,
    attrs = {"src": attr.label(aspects = [flake8])},
)

machine_pylint_report = rule(
    implementation = _machine_report,
    attrs = {"src": attr.label(aspects = [pylint])},
)

machine_yamllint_report = rule(
    implementation = _machine_report,
    attrs = {"src": attr.label(aspects = [yamllint])},
)

machine_clippy_report = rule(
    implementation = _machine_report,
    attrs = {"src": attr.label(aspects = [clippy])},
)
