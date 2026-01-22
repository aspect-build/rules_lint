load("@bazel_lib//lib:expand_make_vars.bzl", _expand_locations = "expand_locations")
load("//lint/private:patcher_action.bzl", "patcher_attrs", _run_patcher = "run_patcher")

def _patcher_run_impl(ctx):
    diff_file = ctx.actions.declare_file("_{}.diff".format(ctx.label.name))

    files_to_diff = ctx.files.files_to_diff
    data = ctx.files.data
    env = ctx.attr.env
    bindir = "."

    inputs = [
        ctx.executable.tool,
    ] + files_to_diff + data

    tool_args = [
        _expand_locations(ctx, arg, ctx.attr.data)
        for arg in ctx.attr.tool_args
    ]

    _run_patcher(
        ctx,
        ctx.executable,
        inputs = inputs,
        args = tool_args,
        files_to_diff = [f.path for f in files_to_diff],
        patch_out = diff_file,
        tools = [ctx.executable.tool],
        patch_cfg_env = dict(env, **{"BAZEL_BINDIR": bindir}),
        env = env,
        mnemonic = ctx.attr.mnemonic,
        progress_message = "Running patcher in %{label} as part of the build",
    )

    return [DefaultInfo(files = depset([diff_file]))]

patcher_run = rule(
    doc = "A rule that wraps patcher_action to make running tests easier.",
    implementation = _patcher_run_impl,
    attrs = patcher_attrs | {
        "tool": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
        ),
        "files_to_diff": attr.label_list(
            mandatory = True,
            allow_files = True,
        ),
        "mnemonic": attr.string(
            default = "Patcher",
        ),
        "tool_args": attr.string_list(
            default = [],
        ),
        "data": attr.label_list(
            default = [],
            allow_files = True,
        ),
        "env": attr.string_dict(
            default = {},
        ),
    },
)
