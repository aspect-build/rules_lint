"""API for declaring a tfsec lint aspect that visits filegroup rules.

Typical usage:

Use [tfsec_aspect](#tfsec_aspect) to declare the tfsec linter aspect, typically in in `tools/lint/linters.bzl`:

```
load("@aspect_rules_lint//lint:tfsec.bzl", "tfsec_aspect")

tfsec = tfsec_aspect(
    binary = "@multitool//tools/tfsec",
)
```

Note that tfsec has noted they are migrating its abilities to [Trivy](https://github.com/aquasecurity/trivy).
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "report_files", "should_visit")

_MNEMONIC = "AspectRulesLintTfsec"

def _tfsec_action(ctx, executable, srcs, stdout, exit_code = None):
    args = ctx.actions.args()
    args.add_all([
        ctx.label.package,
        "--exclude-downloaded-modules",
        "--minimum-severity=HIGH",
    ])
    outputs = [stdout]

    # Tfsec is deprecated, and tells us to use Trivy, ignore it for now until
    # Trivy has fixed some more issues, such as coloured output, as it's output
    # without colours is very hard to parse.
    if exit_code:
        command = "{tfsec} $@ 2>/dev/null >{stdout}; echo $? > " + exit_code.path
        outputs.append(exit_code)
    else:
        command = "{tfsec} $@ 2>/dev/null && touch {stdout}"

    ctx.actions.run_shell(
        inputs = srcs,
        outputs = outputs,
        command = command.format(
            tfsec = executable.path,
            stdout = stdout.path,
        ),
        use_default_shell_env = True,
        arguments = [args],
        mnemonic = _MNEMONIC,
        progress_message = "Scanning %{label} with tfsec",
        tools = [executable],
        execution_requirements = {
            # tfsec does not support symlinks, and finds 0 files when presented with the symlink forest.
            "no-sandbox": "1",
        },
    )

def _tfsec_aspect_impl(target, ctx):
    if should_visit(ctx.rule, [], ctx.attr._filegroup_tags):
        report, exit_code, info = report_files(_MNEMONIC, target, ctx)
        _tfsec_action(ctx, ctx.executable._tfsec, ctx.rule.files.srcs, report, exit_code)
        return [info]

    return []

def tfsec_aspect(binary, filegroup_tags = ["terraform", "scan-with-tfsec"]):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a tfsec executable
        filegroup_tags: which tags on filegroups should be visited by the aspect
    """

    return aspect(
        implementation = _tfsec_aspect_impl,
        attrs = {
            "_options": attr.label(
                default = "@aspect_rules_lint//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_tfsec": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_filegroup_tags": attr.string_list(
                default = filegroup_tags,
            ),
        },
    )
