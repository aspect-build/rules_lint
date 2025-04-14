"Defaults for docgen"

load("@aspect_bazel_lib//lib:docs.bzl", _stardoc_with_diff_test = "stardoc_with_diff_test", _update_docs = "update_docs")

def stardoc_with_diff_test(name, **kwargs):
    _stardoc_with_diff_test(name, renderer = "//tools:stardoc_renderer", **kwargs)

update_docs = _update_docs
