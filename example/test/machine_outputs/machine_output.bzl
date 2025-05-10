"Extracts the machine-readable SARIF report from a target that has been linted with rules_lint."

load("@aspect_bazel_lib//lib:testing.bzl", "assert_json_matches")
load("//tools/lint:linters.bzl", "buf", "clang_tidy", "eslint", "flake8", "ruff", "shellcheck", "stylelint", "vale")

SARIF_TOOL_DRIVER_NAME_FILTER = ".runs[].tool.driver.name"
PHYSICAL_ARTIFACT_LOCATION_URI_FILTER = ".runs[].results | map(.locations | map(.physicalLocation.artifactLocation.uri)) | flatten | unique[]"

def report_test(name, report, expected_tool, expected_uri):
    assert_json_matches(
        name = name,
        file1 = report,
        file2 = report,
        filter1 = SARIF_TOOL_DRIVER_NAME_FILTER,
        filter2 = "\"%s\"" % expected_tool,
    )
    assert_json_matches(
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
