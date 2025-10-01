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

    crate_info = _get_clippy_ready_crate_info(target, ctx)
    if not crate_info:
        noop_lint_action(ctx, outputs)
        return [info]

    # FIXME: Support colors.
    #    color_options = ["--color"] if ctx.attr._options[LintOptionsInfo].color else []
    color_options = []

    # FIXME : does clippy have a --fix mode that applies fixes for some violations while reporting others?

    print("BL: outputs={}".format(outputs))

    raw_human_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_human_report"))
    rust_clippy_action(
        ctx,
        clippy_executable = clippy_bin,
        process_wrapper = ctx.executable._process_wrapper,
        src = crate_info,
        config = ctx.file._config_file,
        output = raw_human_report,
        cap_at_warnings = True,
        # FIXME: Properly handle exit codes, currently rules_rust just writes the file if it's successful.
        #        success_marker = outputs.human.exit_code,
        extra_clippy_flags = color_options + ["--cap-lints=warn"],
    )

    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    rust_clippy_action(
        ctx,
        clippy_executable = clippy_bin,
        process_wrapper = ctx.executable._process_wrapper,
        src = crate_info,
        config = ctx.file._config_file,
        output = raw_machine_report,
        cap_at_warnings = True,
        error_format = "json",
        # FIXME: Properly handle exit codes, currently rules_rust just writes the file if it's successful.
        #        success_marker = outputs.machine.exit_code,
        extra_clippy_flags = [],
    )

    ctx.actions.write(outputs.human.exit_code, "0")

    copy_file_action(ctx, raw_human_report, outputs.human.out)
    ctx.actions.write(outputs.machine.exit_code, "0")
    #    ctx.actions.write(raw_machine_report, "0")

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

# FIXME: The following is vendored from rules_rust, we should expose it from there.
def _get_clippy_ready_crate_info(target, aspect_ctx = None):
    """Check that a target is suitable for clippy and extract the `CrateInfo` provider from it.

    Args:
        target (Target): The target the aspect is running on.
        aspect_ctx (ctx, optional): The aspect's context object.

    Returns:
        CrateInfo, optional: A `CrateInfo` provider if clippy should be run or `None`.
    """

    # Ignore external targets
    if target.label.workspace_root.startswith("external"):
        return None

    # Targets with specific tags will not be formatted
    if aspect_ctx:
        ignore_tags = [
            "no_clippy",
            "no_lint",
            "nolint",
            "noclippy",
        ]
        for tag in aspect_ctx.rule.attr.tags:
            if tag.replace("-", "_").lower() in ignore_tags:
                return None

    # Obviously ignore any targets that don't contain `CrateInfo`
    if rust_common.crate_info in target:
        return target[rust_common.crate_info]
    elif rust_common.test_crate_info in target:
        return target[rust_common.test_crate_info].crate
    else:
        return None
