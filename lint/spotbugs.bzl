"""API for declaring a spotbugs lint aspect that visits java_library and java_binary rules.

Typical usage:

First, call the `fetch_spotbugs` helper in `WORKSPACE` to download the jar file.
Alternatively you could use whatever you prefer for managing Java dependencies, such as a Maven integration rule.

Next, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
java_binary(
    name = "spotbugs",
    main_class = "edu.umd.cs.findbugs.LaunchAppropriateUI",
    runtime_deps = [
        "@spotbugs//:jar",
    ],
)
```

Finally, declare an aspect for it, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:spotbugs.bzl", "lint_spotbugs_aspect")

spotbugs = lint_spotbugs_aspect(
    binary = "@@//tools/lint:spotbugs",
    exclude_filter = "@@//:spotbugs-exclude.xml",
)

```
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "noop_lint_action", "output_files", "should_visit")

_MNEMONIC = "AspectRulesLintSpotbugs"

def spotbugs_action(ctx, executable, srcs, target, exclude_filter, stdout, exit_code = None, options = []):
    """Run Spotbugs as an action under Bazel.

    Based on https://spotbugs.readthedocs.io/en/latest/index.html

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the Spotbugs program
        srcs: jar to be linted
        target: target to be linted
        exclude_filter: label of the spotbugs-exclude.xml file
        stdout: output file to generate
        exit_code: output file to write the exit code.
            If None, then fail the build when Spotbugs exits non-zero.
        options: additional command-line options, see https://spotbugs.readthedocs.io/en/latest/running.html#command-line-options
    """
    inputs = srcs + [exclude_filter]
    deps = target[JavaInfo].transitive_compile_time_jars
    outputs = [stdout]
    args = ctx.actions.args()
    args.add_all(options)

    if exclude_filter:
        args.add_all(["-exclude", exclude_filter.path])

    src_args = ctx.actions.args()
    src_args.add_all(srcs)

    classpath_paths = [jar.path for jar in deps.to_list()]
    if len(classpath_paths) > 0:
        args.add_all(["-auxclasspath", ":".join(classpath_paths)])

    args.add_all(["-exclude", exclude_filter.path])

    if exit_code:
        command = "{SPOTBUGS} $@ >{stdout}; echo $? > " + exit_code.path
        outputs.append(exit_code)
    else:
        # Create empty stdout file on success, as Bazel expects one
        command = "{SPOTBUGS} $@ && touch {stdout}"
    ctx.actions.run_shell(
        inputs = depset(inputs, transitive = [deps]),
        outputs = outputs,
        command = command.format(SPOTBUGS = executable.path, stdout = stdout.path),
        arguments = [args, src_args],
        mnemonic = _MNEMONIC,
        tools = [executable],
        progress_message = "Linting %{label} with Spotbugs",
    )

# buildifier: disable=function-docstrings
def _spotbugs_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []
    srcs = ctx.rule.attr.srcs
    if len(srcs) == 0:
        return []
    files_to_lint = [jar.class_jar for jar in target[JavaInfo].outputs.jars]
    outputs, info = output_files(_MNEMONIC, target, ctx)
    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]
    format_options = []  # to define
    spotbugs_action(ctx, ctx.executable._spotbugs, files_to_lint, target, ctx.file._exclude_filter, outputs.human.out, outputs.human.exit_code, format_options)
    spotbugs_action(ctx, ctx.executable._spotbugs, files_to_lint, target, ctx.file._exclude_filter, outputs.machine.out, outputs.machine.exit_code, format_options)
    return [info]

def lint_spotbugs_aspect(binary, exclude_filter, rule_kinds = ["java_library", "java_binary", "java_test"]):
    return aspect(
        implementation = _spotbugs_aspect_impl,
        # Edges we need to walk up the graph from the selected targets.
        # Needed for linters that need semantic information like transitive type declarations.
        # attr_aspects = ["deps"],
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_spotbugs": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_exclude_filter": attr.label(
                doc = "Report all bug instances except those matching the filter specified by this filter file",
                allow_single_file = True,
                default = exclude_filter,
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
    )

def fetch_spotbugs():
    http_archive(
        name = "spotbugs",
        urls = ["https://github.com/spotbugs/spotbugs/releases/download/4.8.6/spotbugs-4.8.6.zip"],
        strip_prefix = "spotbugs-4.8.6",
        build_file_content = """
java_import(
    name = "jar",
    jars = [
        "lib/spotbugs.jar",
    ],
    visibility = ["//visibility:public"],
)
    """,
    )
