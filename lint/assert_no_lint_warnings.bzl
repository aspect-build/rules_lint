"""Factory function to make lint test rules.

The test will fail when the linter reports any non-empty lint results.
"""

load("@aspect_bazel_lib//lib:paths.bzl", "to_rlocation_path")

def _test_impl(ctx):
    reports = []
    for src in ctx.attr.srcs:
        for report in src[OutputGroupInfo].report.to_list():
            reports.append(report)

    bin = ctx.actions.declare_file("assert_no_lint_warnings.sh")
    ctx.actions.expand_template(
        template = ctx.file._bin,
        output = bin,
        # FIXME: not [0] - need to loop over all reports
        substitutions = {"{{report}}": to_rlocation_path(ctx, reports[0])},
        is_executable = True,
    )
    return [DefaultInfo(
        executable = bin,
        runfiles = ctx.runfiles(reports + [ctx.file._runfiles_lib]),
    )]

def assert_no_lint_warnings(aspect):
    return rule(
        implementation = _test_impl,
        attrs = {
            "srcs": attr.label_list(doc = "*_library targets", aspects = [aspect]),
            "fail_on_violation": attr.bool(),
            "_bin": attr.label(default = ":assert_no_lint_warnings.sh", allow_single_file = True, executable = True, cfg = "exec"),
            "_runfiles_lib": attr.label(default = "@bazel_tools//tools/bash/runfiles", allow_single_file = True),
        },
        test = True,
    )
