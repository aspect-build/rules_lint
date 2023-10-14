"Implementation of formatter_binary"

load("@aspect_bazel_lib//lib:paths.bzl", "to_rlocation_path")

_attrs = {
    "formatters": attr.label_keyed_string_dict(mandatory = True, allow_files = True),
    "_bin": attr.label(default = "//format/private:format.sh", allow_single_file = True),
    "_runfiles_lib": attr.label(default = "@bazel_tools//tools/bash/runfiles", allow_single_file = True),
}

def _formatter_binary_impl(ctx):
    # We need to fill in the rlocation paths in the shell script
    substitutions = {}
    for formatter, lang in ctx.attr.formatters.items():
        rlocation = to_rlocation_path(ctx, formatter.files_to_run.executable)
        if lang.lower() == "python":
            substitutions["{{black}}"] = rlocation
        elif lang.lower() == "starlark":
            substitutions["{{buildifier}}"] = rlocation
        elif lang.lower() == "jsonnet":
            substitutions["{{jsonnet}}"] = rlocation
        elif lang.lower() == "terraform":
            substitutions["{{terraform}}"] = rlocation
        elif lang.lower() in ["javascript", "sql", "bash"]:
            substitutions["{{prettier}}"] = rlocation
        elif lang.lower() == "kotlin":
            substitutions["{{ktfmt}}"] = rlocation
        elif lang.lower() == "java":
            substitutions["{{java-format}}"] = rlocation
        else:
            fail("lang {} not recognized".format(lang))

    bin = ctx.actions.declare_file("format.sh")
    ctx.actions.expand_template(
        template = ctx.file._bin,
        output = bin,
        substitutions = substitutions,
        is_executable = True,
    )
    runfiles = ctx.runfiles(
        [ctx.file._runfiles_lib] +
        [f.files_to_run.executable for f in ctx.attr.formatters.keys()] +
        [f.files_to_run.runfiles_manifest for f in ctx.attr.formatters.keys()],
    ).merge_all(
        [f.default_runfiles for f in ctx.attr.formatters.keys()],
    )

    return [
        DefaultInfo(
            executable = bin,
            runfiles = runfiles,
        ),
    ]

formatter_binary_lib = struct(
    implementation = _formatter_binary_impl,
    attrs = _attrs,
)

multi_formatter_binary = rule(
    doc = "Produces an executable that aggregates the supplied formatter binaries",
    implementation = formatter_binary_lib.implementation,
    attrs = formatter_binary_lib.attrs,
    executable = True,
)
