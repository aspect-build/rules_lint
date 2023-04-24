"eslint implementation details"

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_file_to_bin_action", "copy_files_to_bin_actions")

def eslint_action(ctx, executable, srcs, report, exit_code_out):
    """Create a Bazel Action that spawns an eslint process.

    Adapter for wrapping Bazel around
    https://eslint.org/docs/latest/use/command-line-interface

    Args:
        ctx: an action context OR aspect context
        executable: struct with an eslint field
        srcs: list of file objects to lint
        report: output to create
        exit_code_out: output to create
    """

    args = ctx.actions.args()

    args.add("--no-eslintrc")
    args.add("--debug")
    args.add_all(["--config", ctx.file._config_file.path])
    args.add_all(["--output-file", report.short_path])
    inputs = copy_files_to_bin_actions(ctx, srcs)
    inputs.append(copy_file_to_bin_action(ctx, ctx.file._config_file))
    args.add_all([s.short_path for s in srcs])

    ctx.actions.run(
        inputs = inputs,
        outputs = [report, exit_code_out],
        executable = executable._eslint,
        arguments = [args],
        env = {
            "BAZEL_BINDIR": ctx.bin_dir.path,
            "JS_BINARY__EXIT_CODE_OUTPUT_FILE": exit_code_out.path,
        },
        mnemonic = "ESLint",
    )

def _eslint_aspect_impl(target, ctx):
    report = ctx.actions.declare_file("report")
    exit_code_out = ctx.actions.declare_file("exit_code_out")

    # Make sure the rule has a srcs attribute.
    if hasattr(ctx.rule.attr, "srcs"):
        eslint_action(ctx, ctx.executable, ctx.rule.files.srcs, report, exit_code_out)

    return [
        DefaultInfo(files = depset([report])),
        OutputGroupInfo(
            report = depset([report]),
        )
    ]

eslint_aspect = aspect(
    implementation = _eslint_aspect_impl,
    # attr_aspects = ["deps"],
    attrs = {
        "_eslint": attr.label(
            default = Label("//examples:eslint"),
            executable = True,
            cfg = "exec",
        ),
        "_config_file": attr.label(
            default = "//examples/simple:.eslintrc.cjs",
            allow_single_file = True,
        )
    },
)
