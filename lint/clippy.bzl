"""API for declaring a clippy lint aspect that visits rust_{binary|library|test} rules.

Typical usage:

First, install `rules_rust` into your repository, on at least version 0.67.0: https://bazelbuild.github.io/rules_rust/.
For instance:

```starlark
// MODULE.bazel
bazel_dep(name = "rules_rust", version = "0.67.0")

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

Please watch issue https://github.com/aspect-build/rules_lint/issues/385 for updates on this behavior.
"""

load("@rules_rust//rust:defs.bzl", "rust_clippy_action", "rust_common")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "patch_and_output_files", "should_visit")

_MNEMONIC = "AspectRulesLintClippy"

def _parse_wrapper_output_into_files(ctx, output_file, exit_code_file, raw_process_wrapper_wrapper_output):
    ctx.actions.run_shell(
        command = """
exit_code=$(head -n 1 $1)
output=$(tail -n +2 $1)
echo "${output}" > $2
echo "${exit_code}" > $3
""",
        arguments = [
            raw_process_wrapper_wrapper_output.path,
            output_file.path,
            exit_code_file.path,
        ],
        inputs = [
            raw_process_wrapper_wrapper_output,
        ],
        outputs = [
            output_file,
            exit_code_file,
        ],
    )

# buildifier: disable=function-docstring
def _clippy_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []

    clippy_bin = ctx.toolchains[Label("@rules_rust//rust:toolchain_type")].clippy_driver

    files_to_lint = filter_srcs(ctx.rule)
    if ctx.attr._options[LintOptionsInfo].fix:
        print("WARNING: `fix` is not supported yet for clippy. Please follow https://github.com/aspect-build/rules_lint/issues/385 for updates.")

    # Declare outputs with sibling = crate_info.output when available, so they're placed in the same directory
    # structure that rustc expects. This is required because rust_clippy_action sets --out-dir based on
    # crate_info.output and rustc needs to write .d files to that directory
    crate_info = rust_clippy_action.get_clippy_ready_crate_info(target, ctx)
    sibling = crate_info.output if crate_info else None
    outputs, info = output_files(_MNEMONIC, target, ctx, sibling)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    crate_info = rust_clippy_action.get_clippy_ready_crate_info(target, ctx)
    if not crate_info:
        noop_lint_action(ctx, outputs)
        return [info]

    extra_options = [
        # If we don't pass any clippy options, rules_rust will (rightly) default to -Dwarnings, which turns all warnings into errors.
        # They do this to force Bazel to re-run targets on failures.
        # However, we don't need to do that because we keep track of output files and exit codes separately.
        "-Wwarnings",
    ]
    # FIXME: Implement support for --fix mode. Clippy has a --fix flag, but our patcher doesn't currently support running an action through a macro.
    #        We have to either
    #           (1) modify the patcher so that it can run an action through a macro, or
    #           (2) modify rules_rust so that it gives us a struct with a command line we can run it with the patcher.

    raw_outputs = struct(
        human = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_process_wrapper_wrapper_output_human"), sibling = sibling),
        machine = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_process_wrapper_wrapper_output_machine"), sibling = sibling),
    )

    rust_clippy_action.action(
        ctx,
        clippy_executable = clippy_bin,
        process_wrapper = ctx.executable._process_wrapper_wrapper,
        crate_info = crate_info,
        config = ctx.file._config_file,
        output = raw_outputs.human,
        cap_at_warnings = False,
        extra_clippy_flags = extra_options,
    )

    _parse_wrapper_output_into_files(ctx, outputs.human.out, outputs.human.exit_code, raw_outputs.human)

    rust_clippy_action.action(
        ctx,
        clippy_executable = clippy_bin,
        process_wrapper = ctx.executable._process_wrapper_wrapper,
        crate_info = crate_info,
        config = ctx.file._config_file,
        output = raw_outputs.machine,
        cap_at_warnings = False,
        extra_clippy_flags = extra_options,
        error_format = "json",
    )

    _parse_wrapper_output_into_files(ctx, outputs.machine.out, outputs.machine.exit_code, raw_outputs.machine)

    # FIXME: Rustc only gives us JSON output, which we can't turn into SARIF yet.
    # clippy uses rustc's IO format, which doesn't have a SARIF output mode built in,
    # and they're not planning to add one.
    # We could use clippy-sarif, which seems to be relatively maintained.
    #
    # Refs:
    #  - https://github.com/rust-lang/rust-clippy/issues/8122
    #  - https://github.com/psastras/sarif-rs/tree/main/clippy-sarif
    # parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)

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
        "_process_wrapper_wrapper": attr.label(
            doc = "A wrapper around the rules_rust process wrapper. See @aspect_rules_lint//lint/rust:process_wrapper_wrapper.sh for motivation and documetnation.",
            default = Label("//lint/rust:process_wrapper_wrapper"),
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
