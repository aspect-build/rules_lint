"""Factory function to make lint test rules.

When the linter exits non-zero, the test will print the output of the linter and then fail.

To use this, in your `linters.bzl` where you define the aspect, just create a test that references it.

For example, with `flake8`:

```starlark
load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")
load("@aspect_rules_lint//lint:flake8.bzl", "flake8_aspect")

flake8 = flake8_aspect(
    binary = "@@//:flake8",
    config = "@@//:.flake8",
)

flake8_test = lint_test(aspect = flake8)
```

Now in your BUILD files you can add a test:

```starlark
load("//tools/lint:linters.bzl", "flake8_test")

py_library(
    name = "unused_import",
    srcs = ["unused_import.py"],
)

flake8_test(
    name = "flake8",
    srcs = [":unused_import"],
)
```
"""

load("@aspect_bazel_lib//lib:paths.bzl", "to_rlocation_path")

def _write_assert(ctx, files):
    "Create a parameter to substitute into the shell script"
    output = None
    exit_code = None
    for f in files.to_list():
        if f.path.endswith(".out"):
            output = f
        elif f.path.endswith(".exit_code"):
            exit_code = f
        else:
            fail("rules_lint_human output group contains unrecognized file extension: ", f.path)
    if output and exit_code:
        return "assert_exit_code_zero '{}' '{}'".format(to_rlocation_path(ctx, exit_code), to_rlocation_path(ctx, output))
    if output:
        return "assert_output_empty '{}'".format(to_rlocation_path(ctx, output))
    fail("missing output file among", files)

def _test_impl(ctx):
    bin = ctx.actions.declare_file("{}.lint_test.sh".format(ctx.label.name))
    asserts = [_write_assert(ctx, src[OutputGroupInfo].rules_lint_human) for src in ctx.attr.srcs]

    runfiles = ctx.runfiles(transitive_files = depset(transitive = [src[OutputGroupInfo].rules_lint_human for src in ctx.attr.srcs]))
    runfiles = runfiles.merge(ctx.attr._runfiles_lib[DefaultInfo].default_runfiles)

    ctx.actions.expand_template(
        template = ctx.file._bin,
        output = bin,
        substitutions = {"{{asserts}}": "\n".join(asserts)},
        is_executable = True,
    )
    return [DefaultInfo(
        executable = bin,
        runfiles = runfiles,
    )]

def lint_test(aspect):
    return rule(
        implementation = _test_impl,
        attrs = {
            "srcs": attr.label_list(doc = "*_library targets", aspects = [aspect]),
            "_bin": attr.label(default = ":lint_test.sh", allow_single_file = True, executable = True, cfg = "exec"),
            "_runfiles_lib": attr.label(default = "@bazel_tools//tools/bash/runfiles"),
        },
        test = True,
    )
