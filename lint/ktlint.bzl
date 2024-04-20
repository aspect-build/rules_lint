"""API for calling declaring an ktlint lint aspect.

Typical usage:

Firstly, make sure you're using `rules_jvm_external` to install your Maven dependencies and then add `com.pinterest.ktlint:ktlint-cli` with the linter version to `artifacts` in `maven_install`,
in your WORKSPACE or MODULE.bazel. Then create a `ktlint` binary target to be used in your linter as follows, typically in `tools/linters/BUILD.bazel`:

```
java_binary(
    name = "ktlint",
    main_class = "com.pinterest.ktlint.Main",
    runtime_deps = [
        "@maven//:com_pinterest_ktlint_ktlint_cli",
    ],
)
```

```

Then, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:ktlint.bzl", "ktlint_aspect")

ktlint = ktlint_aspect(
    binary = "@@//tools/linters:ktlint",
    # rules can be enabled/disabled from with this file
    editorconfig = "@@//:.editorconfig",
    # a baseline file with exceptions for violations
    baseline_file = "@@//:.ktlint-baseline.xml",
)
```
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "report_file")

_MNEMONIC = "ktlint"

def ktlint_action(ctx, executable, srcs, editorconfig, report, baseline_file, use_exit_code = False):
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
        use_exit_code: whether a non-zero exit code from ktlint process will result in a build failure.
    """

    args = ctx.actions.args()
    inputs = srcs
    outputs = [report]

    if not use_exit_code:
        args.add(executable.path)

    if editorconfig:
        inputs.append(editorconfig)
        args.add("--editorconfig={}".format(editorconfig.path))
    if baseline_file:
        inputs.append(baseline_file)
        args.add("--baseline={}".format(baseline_file.path))

    args.add("--relative")

    if use_exit_code:
        args.add("--reporter=plain,output={}".format(report.path))
        ctx.actions.run(
            inputs = inputs,
            outputs = outputs,
            executable = executable,
            arguments = [args],
            mnemonic = _MNEMONIC,
        )
    else:
        args.add("--reporter=plain,output={}".format(report.path))
        ctx.actions.run_shell(
            inputs = inputs,
            outputs = outputs,
            command = """
            ktlint=$1
            ktlint_args="${@:2}"
            # Don't fail ktlint and just report the violations
            $ktlint ${ktlint_args} || true
            """,
            mnemonic = _MNEMONIC,
            arguments = [args],
            tools = [executable],
        )

def _ktlint_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["kt_jvm_library", "kt_jvm_binary"]:
        return []

    report, info = report_file(_MNEMONIC, target, ctx)
    ktlint_action(ctx, ctx.executable._ktlint, filter_srcs(ctx.rule), ctx.file._editorconfig, report, ctx.file._baseline_file, ctx.attr._options[LintOptionsInfo].fail_on_violation)
    return [info]

def lint_ktlint_aspect(binary, editorconfig, baseline_file):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a ktlint executable. This needs to be produced in your module/WORKSPACE as follows:

        Add a maven dependency on `com.pinterest.ktlint:ktlint-cli:<version` using `maven_install` repository
        rule from rules_jvm_external
        WORKSPACE
            ```
            load("@rules_jvm_external//:defs.bzl", "maven_install")

            maven_install(
                artifacts = [
                ...
                "com.pinterest.ktlint:ktlint-cli:1.2.1",
                ],
                ...
            )
            ```

        MODULE.bazel
            ```
            maven = use_extension("@rules_jvm_external//:extensions.bzl", "maven")
            maven.install(
                artifacts = [
                    ...
                    "com.pinterest.ktlint:ktlint-cli:1.2.1"
                ],
                ...
            )
            ```

        Now declare a `java_binary` target that produces a ktlint executable using your Java toolchain, typically in `tools/linters/BUILD.bazel` as:

        ```
        java_binary(
            name = "ktlint",
            runtime_deps = [
                "@maven//:com_pinterest_ktlint_ktlint_cli"
            ],
            main_class = "com.pinterest.ktlint.Main"
        )
        ```

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
        },
    )
