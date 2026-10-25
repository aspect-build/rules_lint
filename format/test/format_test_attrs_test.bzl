"Analysis test: format_test passes common test attributes to each generated test"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

_TestAttrsInfo = provider(doc = "Test attributes of the target under test", fields = ["size", "timeout"])

def _test_attrs_aspect_impl(_target, ctx):
    return [_TestAttrsInfo(size = ctx.rule.attr.size, timeout = ctx.rule.attr.timeout)]

_test_attrs_aspect = aspect(implementation = _test_attrs_aspect_impl)

def _test_attrs_test_impl(ctx):
    env = analysistest.begin(ctx)
    info = analysistest.target_under_test(env)[_TestAttrsInfo]
    asserts.equals(env, "small", info.size)
    asserts.equals(env, "short", info.timeout)
    return analysistest.end(env)

test_attrs_test = analysistest.make(
    _test_attrs_test_impl,
    extra_target_under_test_aspects = [_test_attrs_aspect],
)
