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
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "noop_lint_action", "output_files", "should_visit")

_MNEMONIC = "AspectRulesLintPMD"

def pmd_action(ctx, executable, srcs, rulesets, stdout, exit_code = None, options = []):
    """Run PMD as an action under Bazel.

    Based on https://docs.pmd-code.org/latest/pmd_userdocs_installation.html#running-pmd-via-command-line

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the PMD program
        srcs: java files to be linted
        rulesets: list of labels of the PMD ruleset files
        stdout: output file to generate
        exit_code: output file to write the exit code.
            If None, then fail the build when PMD exits non-zero.
        options: additional command-line options, see https://pmd.github.io/pmd/pmd_userdocs_cli_reference.html
    """
    inputs = srcs + rulesets
    outputs = [stdout]

    # Wire command-line options, see
    # https://docs.pmd-code.org/latest/pmd_userdocs_cli_reference.html
    args = ctx.actions.args()
    args.add_all(options)
    args.add("--rulesets")
    args.add_joined(rulesets, join_with = ",")

    src_args = ctx.actions.args()
    src_args.use_param_file("%s", use_always = True)
    src_args.add_all(srcs)

    if exit_code:
        command = "{PMD} $@ >{stdout}; echo $? > " + exit_code.path
        outputs.append(exit_code)
    else:
        # Create empty stdout file on success, as Bazel expects one
        command = "{PMD} $@ && touch {stdout}"

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        command = command.format(PMD = executable.path, stdout = stdout.path),
        arguments = [args, "--file-list", src_args],
        mnemonic = _MNEMONIC,
        tools = [executable],
        progress_message = "Linting %{label} with PMD",
    )

# buildifier: disable=function-docstring
def _pmd_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []

    files_to_lint = filter_srcs(ctx.rule)
    outputs, info = output_files(_MNEMONIC, target, ctx)
    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    # https://github.com/pmd/pmd/blob/master/docs/pages/pmd/userdocs/pmd_report_formats.md
    format_options = ["--format", "textcolor" if ctx.attr._options[LintOptionsInfo].color else "text"]
    pmd_action(ctx, ctx.executable._pmd, files_to_lint, ctx.files._rulesets, outputs.human.out, outputs.human.exit_code, format_options)
    pmd_action(ctx, ctx.executable._pmd, files_to_lint, ctx.files._rulesets, outputs.machine.out, outputs.machine.exit_code)
    return [info]

def lint_pmd_aspect(binary, rulesets, rule_kinds = ["java_binary", "java_library"]):
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
                default = "//lint:options",
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
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
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
