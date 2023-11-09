"Implementation of formatter_binary"

load("@aspect_bazel_lib//lib:paths.bzl", "to_rlocation_path")

_attrs = {
    "javascript": attr.label(doc = "a binary target that runs prettier", executable = True, cfg = "exec", allow_files = True),
    "python": attr.label(doc = "a binary target that runs ruff", executable = True, cfg = "exec", allow_files = True),
    "starlark": attr.label(doc = "a binary target that runs buildifier", executable = True, cfg = "exec", allow_files = True),
    "jsonnet": attr.label(doc = "a binary target that runs jsonnetfmt", executable = True, cfg = "exec", allow_files = True),
    "terraform": attr.label(doc = "a binary target that runs terraform", executable = True, cfg = "exec", allow_files = True),
    "kotlin": attr.label(doc = "a binary target that runs ktfmt", executable = True, cfg = "exec", allow_files = True),
    "java": attr.label(doc = "a binary target that runs google-java-format", executable = True, cfg = "exec", allow_files = True),
    "scala": attr.label(doc = "a binary target that runs scalafmt", executable = True, cfg = "exec", allow_files = True),
    "swift": attr.label(doc = "a binary target that runs swiftformat", executable = True, cfg = "exec", allow_files = True),
    "go": attr.label(doc = "a binary target that runs go fmt", executable = True, cfg = "exec", allow_files = True),
    "sh": attr.label(doc = "a binary target that runs shfmt", executable = True, cfg = "exec", allow_files = True),
    "_bin": attr.label(default = "//format/private:format.sh", allow_single_file = True),
    "_runfiles_lib": attr.label(default = "@bazel_tools//tools/bash/runfiles", allow_single_file = True),
}

def _formatter_binary_impl(ctx):
    # We need to fill in the rlocation paths in the shell script
    substitutions = {
        "{{fix_target}}": str(ctx.label)
    }
    tools = {
        "ruff": ctx.attr.python,
        "buildifier": ctx.attr.starlark,
        "jsonnetfmt": ctx.attr.jsonnet,
        "terraform": ctx.attr.terraform,
        "prettier": ctx.attr.javascript,
        "ktfmt": ctx.attr.kotlin,
        "java-format": ctx.attr.java,
        "swiftformat": ctx.attr.swift,
        "scalafmt": ctx.attr.scala,
        "gofmt": ctx.attr.go,
        "shfmt": ctx.attr.sh,
    }
    for tool, attr in tools.items():
        if attr:
            substitutions["{{%s}}" % tool] = to_rlocation_path(ctx, attr.files_to_run.executable)

    bin = ctx.actions.declare_file("format.sh")
    ctx.actions.expand_template(
        template = ctx.file._bin,
        output = bin,
        substitutions = substitutions,
        is_executable = True,
    )

    runfiles = ctx.runfiles(files = [ctx.file._runfiles_lib] + [
        f.files_to_run.executable
        for f in tools.values()
        if f
    ] + [
        f.files_to_run.runfiles_manifest
        for f in tools.values()
        if f and f.files_to_run.runfiles_manifest
    ])
    runfiles = runfiles.merge_all([
        f.default_runfiles
        for f in tools.values()
        if f
    ])

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
