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

def shellcheck_action(ctx, executable, srcs, config, stdout, exit_code = None, options = []):
    """Run shellcheck as an action under Bazel.

    Based on https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the shellcheck program
        srcs: bash files to be linted
        config: label of the .shellcheckrc file
        stdout: output file containing stdout of shellcheck
        exit_code: output file containing shellcheck exit code.
            If None, then fail the build when vale exits non-zero.
            See https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md#return-values
        options: additional command-line options, see https://github.com/koalaman/shellcheck/blob/master/shellcheck.hs#L95
    """
    inputs = srcs + [config]

    # Wire command-line options, see
    # https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md#options
    args = ctx.actions.args()
    args.add_all(options)
    args.add_all(srcs)
    outputs = [stdout]

    if exit_code:
        command = "{shellcheck} $@ >{stdout}; echo $? >" + exit_code.path
        outputs.append(exit_code)
    else:
        # Create empty file on success, as Bazel expects one
        command = "{shellcheck} $@ && touch {stdout}"

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        command = command.format(
            shellcheck = executable.path,
            stdout = stdout.path,
        ),
        arguments = [args],
        mnemonic = _MNEMONIC,
        tools = [executable],
    )

# buildifier: disable=function-docstring
def _shellcheck_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["sh_binary", "sh_library"]:
        return []

    patch, report, exit_code, info = patch_and_report_files(_MNEMONIC, target, ctx)
    shellcheck_action(ctx, ctx.executable._shellcheck, filter_srcs(ctx.rule), ctx.file._config_file, report, exit_code)
    discard_exit_code = ctx.actions.declare_file("{}.{}.aspect_rules_lint.patch_exit_code".format(_MNEMONIC, target.label.name))
    shellcheck_action(ctx, ctx.executable._shellcheck, filter_srcs(ctx.rule), ctx.file._config_file, patch, discard_exit_code, ["--format", "diff"])
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
