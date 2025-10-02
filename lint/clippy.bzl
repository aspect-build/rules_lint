"""API for declaring a clippy lint aspect that visits rust_{binary|library|test} rules.

Typical usage:

TODO: more setup docs
"""

load("@aspect_bazel_lib//lib:copy_file.bzl", "COPY_FILE_TOOLCHAINS", "copy_file_action")
load("@rules_rust//rust:defs.bzl", "rust_clippy_action", "rust_common")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "patch_and_output_files", "should_visit")

_MNEMONIC = "AspectRulesLintClippy"

# buildifier: disable=function-docstring
def _clippy_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []

    clippy_bin = ctx.toolchains[Label("@rules_rust//rust:toolchain_type")].clippy_driver

    files_to_lint = filter_srcs(ctx.rule)
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    crate_info = rust_clippy_action.get_clippy_ready_crate_info(target, ctx)
    if not crate_info:
        noop_lint_action(ctx, outputs)
        return [info]

    # FIXME : does clippy have a --fix mode that applies fixes for some violations while reporting others?
    # It does, but I'm not sure how to use the patcher with an action that we import.
    extra_options = []
    if ctx.attr._options[LintOptionsInfo].fix:
        pass
        # extra_options += ["--fix"]

    rust_clippy_action.action(
        ctx,
        clippy_executable = clippy_bin,
        process_wrapper = ctx.executable._process_wrapper,
        src = crate_info,
        config = ctx.file._config_file,
        output = outputs.human.out,
        success_marker = outputs.human.exit_code,  # This won't write the exit code, but it wil only write the file if the process has succeeded.
        cap_at_warnings = True,  # We don't want to crash the process if there are clippy errors, we just want to report them.
        extra_clippy_flags = extra_options,
    )

    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    rust_clippy_action.action(
        ctx,
        clippy_executable = clippy_bin,
        process_wrapper = ctx.executable._process_wrapper,
        src = crate_info,
        config = ctx.file._config_file,
        output = raw_machine_report,
        success_marker = outputs.machine.exit_code,  # This won't write the exit code, but it wil only write the file if the process has succeeded.
        cap_at_warnings = True,
        extra_clippy_flags = extra_options,
        error_format = "json",
    )

    # clippy uses rustc's IO format, which doesn't have a SARIF output mode built in,
    # and they're not planning to add one.
    # Ref: https://github.com/rust-lang/rust-clippy/issues/8122
    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)

    return [info]

def lint_clippy_aspect(config, rule_kinds = ["rust_binary", "rust_library", "rust_test"]):
    """A factory function to create a linter aspect.

    The Clippy binary will be read from the Rust toolchain.

    Attrs:
        config (File): Label of the desired Clippy configuration file to use. Reference: https://doc.rust-lang.org/clippy/configuration.html
    """
    attrs = {
        "_options": attr.label(
            default = "//lint:options",
            providers = [LintOptionsInfo],
        ),
        "_config_file": attr.label(
            default = config,
            allow_single_file = True,
        ),
        "_rule_kinds": attr.string_list(
            default = rule_kinds,
        ),
        "_process_wrapper": attr.label(
            doc = "A process wrapper for running clippy on all platforms",
            default = Label("@rules_rust//util/process_wrapper"),
            executable = True,
            cfg = "exec",
        ),
    }
    return aspect(
        fragments = ["cpp"],
        implementation = _clippy_aspect_impl,
        attrs = attrs,
        toolchains = COPY_FILE_TOOLCHAINS + [
            OPTIONAL_SARIF_PARSER_TOOLCHAIN,
            Label("@rules_rust//rust:toolchain_type"),
            "@bazel_tools//tools/cpp:toolchain_type",
        ],
    )
