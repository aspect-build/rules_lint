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

def _bin_file_candidates(target):
    if target == None:
        return []

    files = []
    if JsInfo in target:
        files.extend(target[JsInfo].sources.to_list())

    if DefaultInfo in target:
        files.extend(target[DefaultInfo].files.to_list())

    if OutputGroupInfo in target:
        output_groups = target[OutputGroupInfo]
        if hasattr(output_groups, "_action_inputs"):
            files.extend(output_groups._action_inputs.to_list())

    return files

def copy_or_reuse_bin_inputs(ctx, target, srcs):
    """Return bin-tree inputs for JS tools without duplicating target copy actions.

    When the target provides bin-tree files through JsInfo, DefaultInfo, or
    OutputGroupInfo, reuse those files instead of declaring a second CopyFile
    action for the same source.
    """
    bin_files = {}
    for f in _bin_file_candidates(target):
        if not f.is_source and f.short_path not in bin_files:
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
