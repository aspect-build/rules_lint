"Analysis test: lint_test says which src the aspect skipped, rather than failing on a missing output group"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//lint:lint_test.bzl", "lint_test")

_UnadvertisedInfo = provider(doc = "A provider the target under lint does not advertise", fields = [])

def _skipping_aspect_impl(_target, _ctx):
    return []

# Never runs on the src below, as the clippy aspect never runs on a target from another rules_rust.
_skipping_aspect = aspect(
    implementation = _skipping_aspect_impl,
    required_providers = [_UnadvertisedInfo],
)

skipped_lint_test = lint_test(aspect = _skipping_aspect)

def _no_report_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "the lint aspect produced no report for")
    asserts.expect_failure(env, "//lint/test:unlinted")
    return analysistest.end(env)

no_report_test = analysistest.make(_no_report_test_impl, expect_failure = True)
