"""API for declaring a clippy lint aspect that visits rust_{binary|library|test} rules.

Typical usage:

First, install `rules_rust` into your repository: https://bazelbuild.github.io/rules_rust/. For instance:

```starlark
// MODULE.bazel
bazel_dep(name = "rules_rust", version = "0.50.1")

rust = use_extension("@rules_rust//rust:extensions.bzl", "rust")
rust.toolchain(
    edition = "2021",
    versions = ["1.75.0"],
)
use_repo(rust, "rust_toolchains")

register_toolchains(
    "@rust_toolchains//:all",
)
```

This will install a rust toolchain, which includes rustc and clippy.
Please ignore the `rules_rust` instructions around clippy, as `rules_lint` ignores all `rules_rust` flags.

Next, create a clippy configuration file. We'll assume you've created it in `//:.clippy.toml`.
The file name must be suffixed by either `.clippy.toml` or `clippy.toml`, otherwise clippy will silently ignore it.

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:clippy.bzl", "lint_clippy_aspect")

clippy = lint_clippy_aspect(
    config = Label("//:.clippy.toml"),
)
```

Now your targets will be linted with clippy.
If you wish a target to be excluded from linting, you can give them the `noclippy` tag.
"""

load("@rules_rust//rust:defs.bzl", "rust_clippy_action", "rust_common")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "patch_and_output_files", "should_visit")

_MNEMONIC = "AspectRulesLintClippy"

def _marker_to_exit_code(ctx, marker, exit_code):
    """Write 0 to exit_code if marker exists, fail otherwise.

    rules_rust won't write the exit code to the success_marker, so we assert that it exists and write the exit code ourselves.
    If there is no success marker, the action has failed anyway.

    Args:
        ctx (ctx): The rule or aspect context. Must have access to `ctx.actions.run_shell`
        marker (File): A file that will only exist if the action has succeeded
        exit_code (File): A file that will be written with the exit code 0 if marker exists
    """
    ctx.actions.run_shell(
        outputs = [exit_code],
        inputs = [marker],
        arguments = [exit_code.path],
        command = "echo '0' > $1",
    )

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

    extra_options = []
    # FIXME: Implement support for --fix mode. Clippy has a --fix flag, but our patcher doesn't currently support running an action through a macro.
    #        We have to either
    #           (1) modify the patcher so that it can run an action through a macro, or
    #           (2) modify rules_rust so that it gives us a struct with a command line we can run it with the patcher.

    human_success_indicator = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "human_success_indicator"))
    rust_clippy_action.action(
        ctx,
        clippy_executable = clippy_bin,
        process_wrapper = ctx.executable._process_wrapper,
        crate_info = crate_info,
        config = ctx.file._config_file,
        output = outputs.human.out,
        success_marker = human_success_indicator,
        cap_at_warnings = True,  # We don't want to crash the process if there are clippy errors, we just want to report them.
        extra_clippy_flags = extra_options,
    )
    _marker_to_exit_code(ctx, human_success_indicator, outputs.human.exit_code)

    machine_success_indicator = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "machine_success_indicator"))
    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    rust_clippy_action.action(
        ctx,
        clippy_executable = clippy_bin,
        process_wrapper = ctx.executable._process_wrapper,
        crate_info = crate_info,
        config = ctx.file._config_file,
        output = raw_machine_report,
        success_marker = machine_success_indicator,
        cap_at_warnings = True,
        extra_clippy_flags = extra_options,
        error_format = "json",
    )
    _marker_to_exit_code(ctx, machine_success_indicator, outputs.machine.exit_code)

    # clippy uses rustc's IO format, which doesn't have a SARIF output mode built in,
    # and they're not planning to add one.
    # Ref: https://github.com/rust-lang/rust-clippy/issues/8122
    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)

    return [info]

DEFAULT_RULE_KINDS = ["rust_binary", "rust_library", "rust_test"]

def lint_clippy_aspect(config, rule_kinds = DEFAULT_RULE_KINDS):
    """A factory function to create a linter aspect.

    The Clippy binary will be read from the Rust toolchain.

    Args:
        config (File): Label of the desired Clippy configuration file to use. Reference: https://doc.rust-lang.org/clippy/configuration.html
        rule_kinds (List[str]): List of rule kinds to lint. Defaults to {default_rule_kinds}.
    """.format(default_rule_kinds = DEFAULT_RULE_KINDS)
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
        toolchains = [
            OPTIONAL_SARIF_PARSER_TOOLCHAIN,
            Label("@rules_rust//rust:toolchain_type"),
            "@bazel_tools//tools/cpp:toolchain_type",
        ],
    )
