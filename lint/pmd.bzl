"""API for declaring a PMD lint aspect that visits java_library rules.

Typical usage:

First, call the `fetch_pmd` helper in `WORKSPACE` to download the zip file.
Alternatively you could use whatever you prefer for managing Java dependencies, such as a Maven integration rule.

Next, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
java_binary(
    name = "pmd",
    main_class = "net.sourceforge.pmd.PMD",
    runtime_deps = ["@net_sourceforge_pmd"],
)
```

Finally, declare an aspect for it, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:pmd.bzl", "pmd_aspect")

pmd = pmd_aspect(
    binary = "@@//tools/lint:pmd",
    rulesets = ["@@//:pmd.xml"],
)
```
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "report_file")

_MNEMONIC = "PMD"

def pmd_action(ctx, executable, srcs, rulesets, report, use_exit_code = False):
    """Run PMD as an action under Bazel.

    Based on https://docs.pmd-code.org/latest/pmd_userdocs_installation.html#running-pmd-via-command-line

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the PMD program
        srcs: java files to be linted
        rulesets: list of labels of the PMD ruleset files
        report: output file to generate
        use_exit_code: whether to fail the build when a lint violation is reported
    """
    inputs = srcs + rulesets

    # Wire command-line options, see
    # https://docs.pmd-code.org/latest/pmd_userdocs_cli_reference.html
    args = ctx.actions.args()
    args.add("--rulesets")
    args.add_joined(rulesets, join_with = ",")

    src_args = ctx.actions.args()
    src_args.use_param_file("%s", use_always = True)
    src_args.add_all(srcs)

    if use_exit_code:
        ctx.actions.run_shell(
            inputs = inputs,
            outputs = [report],
            command = executable.path + " $@ && touch " + report.path,
            arguments = [args, "--file-list", src_args],
            mnemonic = _MNEMONIC,
            tools = [executable],
        )
    else:
        args.add_all(["--report-file", report])

        # NB: this arg changes in PMD 7
        args.add_all(["--fail-on-violation", "false"])
        ctx.actions.run(
            inputs = inputs,
            outputs = [report],
            executable = executable,
            arguments = [args, "--file-list", src_args],
            mnemonic = _MNEMONIC,
        )

# buildifier: disable=function-docstring
def _pmd_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["java_binary", "java_library"]:
        return []

    report, info = report_file(_MNEMONIC, target, ctx)
    pmd_action(ctx, ctx.executable._pmd, filter_srcs(ctx.rule), ctx.files._rulesets, report, ctx.attr._options[LintOptionsInfo].fail_on_violation)
    return [info]

def lint_pmd_aspect(binary, rulesets):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a PMD executable. Can be obtained from rules_java like so:

            ```
            java_binary(
                name = "pmd",
                main_class = "net.sourceforge.pmd.PMD",
                # Point to wherever you have the java_import rule defined, see our example
                runtime_deps = ["@net_sourceforge_pmd"],
            )
            ```

        rulesets: the PMD ruleset XML files
    """
    return aspect(
        implementation = _pmd_aspect_impl,
        # Edges we need to walk up the graph from the selected targets.
        # Needed for linters that need semantic information like transitive type declarations.
        # attr_aspects = ["deps"],
        attrs = {
            "_options": attr.label(
                default = "//lint:fail_on_violation",
                providers = [LintOptionsInfo],
            ),
            "_pmd": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_rulesets": attr.label_list(
                allow_files = True,
                mandatory = True,
                allow_empty = False,
                doc = "Ruleset files.",
                default = rulesets,
            ),
        },
    )

def fetch_pmd():
    http_archive(
        name = "net_sourceforge_pmd",
        build_file_content = """java_import(name = "net_sourceforge_pmd", jars = glob(["*.jar"]), visibility = ["//visibility:public"])""",
        sha256 = "21acf96d43cb40d591cacccc1c20a66fc796eaddf69ea61812594447bac7a11d",
        strip_prefix = "pmd-bin-6.55.0/lib",
        url = "https://github.com/pmd/pmd/releases/download/pmd_releases/6.55.0/pmd-bin-6.55.0.zip",
    )
