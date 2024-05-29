"API for linter aspect providers and helper functions"

load(
    "//lint/private:lint_aspect.bzl",
    _LintOptionsInfo = "LintOptionsInfo",
    _patch_and_report_files = "patch_and_report_files",
    _report_files = "report_files",
)

LintOptionsInfo = _LintOptionsInfo
report_files = _report_files
patch_and_report_files = _patch_and_report_files
