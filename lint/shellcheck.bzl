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

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "noop_lint_action", "output_files", "patch_and_output_files", "should_visit")

_MNEMONIC = "AspectRulesLintShellCheck"
_OUTFILE_FORMAT = "{label}.{mnemonic}.{suffix}"

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
        progress_message = "Linting %{label} with ShellCheck",
        tools = [executable],
    )

# buildifier: disable=function-docstring
def _shellcheck_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []

    files_to_lint = filter_srcs(ctx.rule)
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    color_options = ["--color"] if ctx.attr._options[LintOptionsInfo].color else []
    config_options = ["--rcfile", ctx.file._config_file]

    # shellcheck does not have a --fix mode that applies fixes for some violations while reporting others.
    # So we must run an action to generate the report separately from an action that writes the human-readable report.
    if hasattr(outputs, "patch"):
        discard_exit_code = ctx.actions.declare_file(_OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "patch_exit_code"))
        shellcheck_action(ctx, ctx.executable._shellcheck, files_to_lint, ctx.file._config_file, outputs.patch, discard_exit_code, ["--format", "diff"])

    shellcheck_action(ctx, ctx.executable._shellcheck, files_to_lint, ctx.file._config_file, outputs.human.out, outputs.human.exit_code, color_options + config_options)
    shellcheck_action(ctx, ctx.executable._shellcheck, files_to_lint, ctx.file._config_file, outputs.machine.out, outputs.machine.exit_code, config_options)

    return [info]

def lint_shellcheck_aspect(binary, config, rule_kinds = ["sh_binary", "sh_library", "sh_test"]):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a shellcheck executable.
        config: the .shellcheckrc file
    """
    return aspect(
        implementation = _shellcheck_aspect_impl,
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
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
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
    )
