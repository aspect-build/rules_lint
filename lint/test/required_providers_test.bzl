"""Verify provider filtering happens before linter tool dependencies are analyzed."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_python//python:defs.bzl", "PyInfo")
load("//lint:ruff.bzl", "lint_ruff_aspect")
load("//lint:ty.bzl", "lint_ty_aspect")

_TOOL_ERROR = "linter tool dependency was analyzed"

def _unavailable_linter_impl(_ctx):
    fail(_TOOL_ERROR)

unavailable_linter = rule(
    implementation = _unavailable_linter_impl,
    executable = True,
)

def _python_target_impl(_ctx):
    return [PyInfo(transitive_sources = depset())]

python_target = rule(
    implementation = _python_target_impl,
    provides = [PyInfo],
)

# A failing tool makes unnecessary dependency analysis observable. These tests
# never execute a linter or depend on downloaded linter binaries.
_ruff = lint_ruff_aspect(
    binary = Label("//lint/test:unavailable_linter"),
    configs = [],
    rule_kinds = ["*"],
    required_providers = [PyInfo],
)

_ty = lint_ty_aspect(
    binary = Label("//lint/test:unavailable_linter"),
    config = Label("//lint/test:lint_test_xml_test.sh"),
    rule_kinds = ["*"],
    required_providers = [PyInfo],
)

_default_ruff = lint_ruff_aspect(
    binary = Label("//lint/test:unavailable_linter"),
    configs = [],
)

_default_ty = lint_ty_aspect(
    binary = Label("//lint/test:unavailable_linter"),
    config = Label("//lint/test:lint_test_xml_test.sh"),
)

def _skips_target_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    asserts.false(env, OutputGroupInfo in target and hasattr(target[OutputGroupInfo], "rules_lint_human"))
    return analysistest.end(env)

def _requires_tool_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, _TOOL_ERROR)
    return analysistest.end(env)

ruff_skips_target_test = analysistest.make(
    _skips_target_test_impl,
    extra_target_under_test_aspects = [_ruff],
)

ty_skips_target_test = analysistest.make(
    _skips_target_test_impl,
    extra_target_under_test_aspects = [_ty],
)

ruff_requires_tool_test = analysistest.make(
    _requires_tool_test_impl,
    expect_failure = True,
    extra_target_under_test_aspects = [_ruff],
)

ty_requires_tool_test = analysistest.make(
    _requires_tool_test_impl,
    expect_failure = True,
    extra_target_under_test_aspects = [_ty],
)

ruff_default_requires_tool_test = analysistest.make(
    _requires_tool_test_impl,
    expect_failure = True,
    extra_target_under_test_aspects = [_default_ruff],
)

ty_default_requires_tool_test = analysistest.make(
    _requires_tool_test_impl,
    expect_failure = True,
    extra_target_under_test_aspects = [_default_ty],
)
