"Common utilities for testing machine-readable SARIF reports from linter aspects."

load("@bazel_features//:features.bzl", "bazel_features")
load("@jq.bzl//jq:jq.bzl", "jq_test")

SARIF_TOOL_DRIVER_NAME_FILTER = ".runs[].tool.driver.name"
PHYSICAL_ARTIFACT_LOCATION_URI_FILTER = ".runs[].results | map(.locations | map(.physicalLocation.artifactLocation.uri)) | flatten | unique[]"

def report_test(name, report, expected_tool, expected_uri):
    """Test that a SARIF report has the expected tool name and URI.

    Args:
        name: Name for the test target
        report: Label of the report file
        expected_tool: Expected tool driver name (e.g., "PMD", "ESLint")
        expected_uri: Expected file URI in the report
    """

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
    """Implementation for machine report rules that extract SARIF reports from linted targets."""
    files = ctx.attr.src[OutputGroupInfo].rules_lint_machine.to_list()
    return [DefaultInfo(files = depset([r for r in files if r.path.endswith(".report")]))]

def machine_report_rule(aspect):
    """Creates a rule that extracts machine-readable SARIF reports from a target linted with the given aspect.

    Args:
        aspect: The linter aspect to apply

    Returns:
        A rule that can be used to extract SARIF reports
    """
    return rule(
        implementation = _machine_report,
        attrs = {"src": attr.label(aspects = [aspect])},
    )
