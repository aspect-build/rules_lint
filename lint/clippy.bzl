"""API for declaring a clippy lint aspect that visits rust_{binary|library|test} rules.

Typical usage:

TODO: more setup docs
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "patch_and_output_files", "should_visit")

_MNEMONIC = "AspectRulesLintClippy"

def clippy_action(ctx, executable, srcs, config, stdout, exit_code = None, options = []):
    # We can probably just get this from rules_rust
    pass

# buildifier: disable=function-docstring
def _clippy_aspect_impl(target, ctx):
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

    # FIXME : does clippy have a --fix mode that applies fixes for some violations while reporting others?

    clippy_action(ctx, ctx.executable._clippy, files_to_lint, ctx.file._config_file, outputs.human.out, outputs.human.exit_code, color_options + config_options)
    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    clippy_action(ctx, ctx.executable._clippy, files_to_lint, ctx.file._config_file, raw_machine_report, outputs.machine.exit_code, config_options)

    # FIXME: does clippy have a SARIF output format built-in? Do we have to parse it?
    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)

    return [info]

def lint_clippy_aspect(binary, config, rule_kinds = ["rust_binary", "rust_library", "rust_test"]):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a clippy executable.
        config: TODO: how is clippy configured?
    """
    return aspect(
        implementation = _clippy_aspect_impl,
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_clippy": attr.label(
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
        toolchains = [OPTIONAL_SARIF_PARSER_TOOLCHAIN],
    )
