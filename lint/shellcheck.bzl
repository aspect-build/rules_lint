"""API for declaring a shellcheck lint aspect that visits sh_library rules.

Typical usage:

Use [shellcheck_aspect](#shellcheck_aspect) to declare the shellcheck linter aspect, typically in in `tools/lint/linters.bzl`:

```
load("@aspect_rules_lint//lint:shellcheck.bzl", "shellcheck_aspect")

shellcheck = shellcheck_aspect(
    binary = "@multitool//tools/shellcheck",
    config = "@@//:.shellcheckrc",
)
```
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "patch_and_report_files")

_MNEMONIC = "shellcheck"

def shellcheck_action(ctx, executable, srcs, config, output, use_exit_code = False, options = []):
    """Run shellcheck as an action under Bazel.

    Based on https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the shellcheck program
        srcs: bash files to be linted
        config: label of the .shellcheckrc file
        output: output file to generate
        use_exit_code: whether to fail the build when a lint violation is reported
        options: additional command-line options, see https://github.com/koalaman/shellcheck/blob/master/shellcheck.hs#L95
    """
    inputs = srcs + [config]

    # Wire command-line options, see
    # https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md#options
    args = ctx.actions.args()
    args.add_all(options)
    args.add_all(srcs)

    if use_exit_code:
        command = "{shellcheck} $@ && touch {report}"
    else:
        command = "{shellcheck} $@ >{report} || true"

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [output],
        command = command.format(
            shellcheck = executable.path,
            report = output.path,
        ),
        arguments = [args],
        mnemonic = _MNEMONIC,
        tools = [executable],
    )

# buildifier: disable=function-docstring
def _shellcheck_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["sh_binary", "sh_library"]:
        return []

    patch, report, info = patch_and_report_files(_MNEMONIC, target, ctx)
    shellcheck_action(ctx, ctx.executable._shellcheck, filter_srcs(ctx.rule), ctx.file._config_file, report, ctx.attr._options[LintOptionsInfo].fail_on_violation)
    shellcheck_action(ctx, ctx.executable._shellcheck, filter_srcs(ctx.rule), ctx.file._config_file, patch, False, ["--format", "diff"])
    return [info]

def lint_shellcheck_aspect(binary, config):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a shellcheck executable.
        config: the .shellcheckrc file
    """
    return aspect(
        implementation = _shellcheck_aspect_impl,
        attrs = {
            "_options": attr.label(
                default = "//lint:fail_on_violation",
                providers = [LintOptionsInfo],
            ),
            "_shellcheck": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(
                default = config,
                allow_single_file = True,
            ),
        },
    )
