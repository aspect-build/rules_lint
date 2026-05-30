"Helpers for JavaScript linter inputs"

load(
    "@aspect_rules_js//js:providers.bzl",
    "JsInfo",
)
load(
    "@bazel_lib//lib:copy_to_bin.bzl",
    _COPY_FILE_TO_BIN_TOOLCHAINS = "COPY_FILE_TO_BIN_TOOLCHAINS",
    _copy_files_to_bin_actions = "copy_files_to_bin_actions",
)

COPY_FILE_TO_BIN_TOOLCHAINS = _COPY_FILE_TO_BIN_TOOLCHAINS

def copy_or_reuse_bin_inputs(ctx, target, srcs):
    """Return bin-tree inputs for JS tools without duplicating target copy actions.

    When the target provides JsInfo, its `sources` depset already contains the
    bin-tree mirror of the target's srcs (produced by e.g. ts_project's own
    copy-to-bin action). Reusing those files avoids declaring a second
    CopyFile action with conflicting execution_info, which fails analysis on
    bazel-lib >= 3.1.0.
    """
    bin_files = {}
    if target != None and JsInfo in target:
        for f in target[JsInfo].sources.to_list():
            if not f.is_source:
                bin_files[f.short_path] = f

    inputs = []
    to_copy = []
    for src in srcs:
        if src.is_source:
            bin_file = bin_files.get(src.short_path)
            if bin_file:
                inputs.append(bin_file)
            else:
                to_copy.append(src)
        else:
            inputs.append(src)

    if to_copy:
        inputs.extend(_copy_files_to_bin_actions(ctx, to_copy))

    return inputs
