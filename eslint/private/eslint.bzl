"eslint implementation details"

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_files_to_bin_actions")

def eslint_action(ctx, executable, srcs, report):
    """Create a Bazel Action that spawns an eslint process.

    Adapter for wrapping Bazel around
    https://eslint.org/docs/latest/use/command-line-interface

    Args:
        ctx: an action context OR aspect context
        executable: struct with an eslint field
        srcs: list of file objects to lint
        report: output to create
    """

    args = ctx.actions.args()

    args.extend(["--output-file", report.path])
    inputs = copy_files_to_bin_actions(ctx, srcs)
    args.extend([s.short_path for s in srcs])

    ctx.actions.run(
        inputs = inputs,
        outputs = [report],
        executable = executable._eslint,
        arguments = [args],
        env = {
            "BAZEL_BINDIR": ctx.bin_dir.path,
        },
        mnemonic = "ESLint",
    )

def _eslint_aspect_impl(target, ctx):
    # Make sure the rule has a srcs attribute.
    if hasattr(ctx.rule.attr, "srcs"):
        eslint_action(ctx, ctx.executable, ctx.rule.attr.srcs, ctx.actions.declare_file("report"))

    return []

eslint_aspect = aspect(
    implementation = _eslint_aspect_impl,
    attr_aspects = ["deps"],
    attrs = {
        "_eslint": attr.label(
            default = Label("//examples:node_modules/eslint"),
            executable = True,
            cfg = "exec",
        ),
    },
)
