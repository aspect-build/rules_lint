"""API for calling declaring an ktlint lint aspect.

Typical usage:
Make sure you have `ktlint` pulled as a dependency into your WORKSPACE/module by pulling a version of it from here
https://github.com/pinterest/ktlint/releases and using a `http_file` declaration for it like.

```
http_file(
    name = "com_github_pinterest_ktlint",
    sha256 = "2e28cf46c27d38076bf63beeba0bdef6a845688d6c5dccd26505ce876094eb92",
    url = "https://github.com/pinterest/ktlint/releases/download/1.2.1/ktlint",
    executable = True,
)
```

Then, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:ktlint.bzl", "ktlint_aspect")

ktlint = ktlint_aspect(
    binary = "@@com_github_pinterest_ktlint//file",
    # rules can be enabled/disabled from with this file
    editorconfig = "@@//:.editorconfig",
    # a baseline file with exceptions for violations
    baseline_file = "@@//:.ktlint-baseline.xml",
)
```
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "report_file")

_MNEMONIC = "ktlint"

def ktlint_action(ctx, executable, srcs, editorconfig, report, baseline_file, java_runtime, use_exit_code = False):
    """ Runs ktlint as build action in Bazel.

    Adapter for wrapping Bazel around
    https://pinterest.github.io/ktlint/latest/install/cli/

    Args:
        ctx: an action context or aspect context
        executable: struct with ktlint field
        srcs: A list of source files to lint
        editorconfig: The file object pointing to the editorconfig file used by ktlint
        report: :output:  the stdout of ktlint containing any violations found
        baseline_file: The file object pointing to the baseline file used by ktlint.
        java_runtime: The Java Runtime configured for this build, pulled from the registered toolchain.
        use_exit_code: whether a non-zero exit code from ktlint process will result in a build failure.
    """

    args = ctx.actions.args()
    inputs = srcs
    outputs = [report]

    # ktlint artifact is published as an "executable" script which calls the fat jar
    # so we need to pass a hermetic Java runtime from our build to avoid relying on
    # system Java
    java_home = java_runtime[java_common.JavaRuntimeInfo].java_home
    java_runtime_files = java_runtime[java_common.JavaRuntimeInfo].files
    env = {
        "JAVA_HOME": java_home,
    }

    args.add(executable.path)
    inputs.append(executable)

    if editorconfig:
        inputs.append(editorconfig)
        args.add("--editorconfig={}".format(editorconfig.path))
    if baseline_file:
        inputs.append(baseline_file)
        args.add("--baseline={}".format(baseline_file.path))

    args.add("--relative")
    args.add("--reporter=plain,output={}".format(report.path))

    # Include source files and Java runtime files required for ktlint
    inputs = depset(direct = inputs, transitive = [java_runtime_files])

    if use_exit_code:
        command = """
            # This makes hermetic java available to ktlint executable
            export PATH=$PATH:$JAVA_HOME/bin
            ktlint=$1
            ktlint_args="${@:2}"

            # Run ktlint with arguments passed
            $ktlint ${ktlint_args}
            """
    else:
        command = """
            # This makes hermetic java available to ktlint executable
            export PATH=$PATH:$JAVA_HOME/bin
            ktlint=$1
            ktlint_args="${@:2}"

            # Don't fail ktlint and just report the violations
            $ktlint ${ktlint_args} || true
            """

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        command = command,
        arguments = [args],
        mnemonic = _MNEMONIC,
        env = env,
    )

def _ktlint_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["kt_jvm_library", "kt_jvm_binary", "kt_js_library"]:
        return []

    report, info = report_file(_MNEMONIC, target, ctx)
    ktlint_action(ctx, ctx.executable._ktlint, filter_srcs(ctx.rule), ctx.file._editorconfig, report, ctx.file._baseline_file, ctx.attr._java_runtime, ctx.attr._options[LintOptionsInfo].fail_on_violation)
    return [info]

def lint_ktlint_aspect(binary, editorconfig, baseline_file):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a ktlint executable, provided as file typically through http_file declaration or using fetch_ktlint in your WORKSPACE.
        editorconfig: The label of the file pointing to the .editorconfig file used by ktlint.
        baseline_file: An optional attribute pointing to the label of the baseline file used by ktlint.
    """
    return aspect(
        implementation = _ktlint_aspect_impl,
        # Edges we need to walk up the graph from the selected targets.
        # Needed for linters that need semantic information like transitive type declarations.
        # attr_aspects = ["deps"],
        attrs = {
            "_options": attr.label(
                default = "//lint:fail_on_violation",
                providers = [LintOptionsInfo],
            ),
            "_ktlint": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_editorconfig": attr.label(
                default = editorconfig,
                allow_single_file = True,
            ),
            "_baseline_file": attr.label(
                default = baseline_file,
                allow_single_file = True,
            ),
            "_java_runtime": attr.label(
                default = "@bazel_tools//tools/jdk:current_java_runtime",
            ),
        },
        toolchains = [
            "@bazel_tools//tools/jdk:toolchain_type",
        ],
    )

def fetch_ktlint():
    http_file(
        name = "com_github_pinterest_ktlint",
        sha256 = "2e28cf46c27d38076bf63beeba0bdef6a845688d6c5dccd26505ce876094eb92",
        url = "https://github.com/pinterest/ktlint/releases/download/1.2.1/ktlint",
        executable = True,
    )
