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

If you plan on using Ktlint [custom rulesets](https://pinterest.github.io/ktlint/1.2.1/install/cli/#rule-sets), you can also declare
an additional `ruleset_jar` attribute pointing to your custom ruleset jar like this

```
java_binary(
    name = "my_ktlint_custom_ruleset",
    ...
)

ktlint = ktlint_aspect(
    binary = "@@com_github_pinterest_ktlint//file",
    # rules can be enabled/disabled from with this file
    editorconfig = "@@//:.editorconfig",
    # a baseline file with exceptions for violations
    baseline_file = "@@//:.ktlint-baseline.xml",
    # Run your custom ktlint ruleset on top of standard rules
    ruleset_jar = "@@//:my_ktlint_custom_ruleset_deploy.jar",
)
```

If your custom ruleset is a third-party dependency and not a first-party dependency, you can also fetch it using `http_file` and use it instead.
"""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "dummy_successful_lint_action", "filter_srcs", "report_files")

_MNEMONIC = "AspectRulesLintKTLint"

def ktlint_action(ctx, executable, srcs, editorconfig, stdout, baseline_file, java_runtime, ruleset_jar = None, exit_code = None):
    """ Runs ktlint as build action in Bazel.

    Adapter for wrapping Bazel around
    https://pinterest.github.io/ktlint/latest/install/cli/

    Args:
        ctx: an action context or aspect context
        executable: struct with ktlint field
        srcs: A list of source files to lint
        editorconfig: The file object pointing to the editorconfig file used by ktlint
        stdout: :output:  the stdout of ktlint containing any violations found
        baseline_file: The file object pointing to the baseline file used by ktlint.
        java_runtime: The Java Runtime configured for this build, pulled from the registered toolchain.
        ruleset_jar: An optional, custom ktlint ruleset jar.
        exit_code: output file to write the exit code.
            If None, then fail the build when ktlint exits non-zero.
    """

    args = ctx.actions.args()
    inputs = srcs
    outputs = [stdout]

    # ktlint artifact is published as an "executable" script which calls the fat jar
    # so we need to pass a hermetic Java runtime from our build to avoid relying on
    # system Java
    java_home = java_runtime[java_common.JavaRuntimeInfo].java_home
    java_runtime_files = java_runtime[java_common.JavaRuntimeInfo].files
    env = {
        "JAVA_HOME": java_home,
    }

    inputs.append(executable)

    if editorconfig:
        inputs.append(editorconfig)
        args.add("--editorconfig={}".format(editorconfig.path))
    if baseline_file:
        inputs.append(baseline_file)
        args.add("--baseline={}".format(baseline_file.path))
    if ruleset_jar:
        inputs.append(ruleset_jar)
        args.add("--ruleset={}".format(ruleset_jar.path))

    args.add("--relative")

    # Include source files and Java runtime files required for ktlint
    inputs = depset(direct = inputs, transitive = [java_runtime_files])

    # This makes hermetic java available to ktlint executable
    command = "export PATH=$PATH:$JAVA_HOME/bin\n"

    if exit_code:
        # Don't fail ktlint and just report the violations
        command += "{ktlint} $@ >{stdout}; echo $? >" + exit_code.path
        outputs.append(exit_code)
    else:
        # Run ktlint with arguments passed
        command += "{ktlint} $@ && touch {stdout}"

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        command = command.format(ktlint = executable.path, stdout = stdout.path),
        arguments = [args],
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with Ktlint",
        env = env,
    )

def _ktlint_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["kt_jvm_library", "kt_jvm_binary", "kt_js_library"]:
        return []

    report, exit_code, info = report_files(_MNEMONIC, target, ctx)
    ruleset_jar = None
    if hasattr(ctx.attr, "_ruleset_jar"):
        ruleset_jar = ctx.file._ruleset_jar

    files_to_lint = filter_srcs(ctx.rule)

    if len(files_to_lint) == 0:
        dummy_successful_lint_action(ctx, report, exit_code)
    else:
        ktlint_action(ctx, ctx.executable._ktlint, files_to_lint, ctx.file._editorconfig, report, ctx.file._baseline_file, ctx.attr._java_runtime, ruleset_jar, exit_code)
    return [info]

def lint_ktlint_aspect(binary, editorconfig, baseline_file, ruleset_jar = None):
    """A factory function to create a linter aspect.

    Args:
        binary: a ktlint executable, provided as file typically through http_file declaration or using fetch_ktlint in your WORKSPACE.
        editorconfig: The label of the file pointing to the .editorconfig file used by ktlint.
        baseline_file: An optional attribute pointing to the label of the baseline file used by ktlint.
        ruleset_jar: An optional, custom ktlint ruleset provided as a fat jar, and works on top of the standard rules.

    Returns:
        An aspect definition for ktlint
    """

    # Attr defaults cannot be None, so this is added only if a
    # ruleset jar is specified
    extra_attrs = {}
    if ruleset_jar:
        extra_attrs = {
            "_ruleset_jar": attr.label(
                default = ruleset_jar,
                allow_single_file = True,
            ),
        }

    return aspect(
        implementation = _ktlint_aspect_impl,
        # Edges we need to walk up the graph from the selected targets.
        # Needed for linters that need semantic information like transitive type declarations.
        # attr_aspects = ["deps"],
        attrs = dicts.add({
            "_options": attr.label(
                default = "//lint:options",
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
        }, extra_attrs),
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
