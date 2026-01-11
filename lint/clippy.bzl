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

def _parse_wrapper_output_into_files(ctx, outputs, raw_process_wrapper_wrapper_output):
    ctx.actions.run_shell(
        command = """
exit_code=$(head -n 1 $1)
output=$(tail -n +2 $1)
echo "${output}" > $2
echo "${exit_code}" > $3
echo "${exit_code}" > $4
""",
        arguments = [
            raw_process_wrapper_wrapper_output.path,
            outputs.human.out.path,
            outputs.human.exit_code.path,
            outputs.machine.exit_code.path,
        ],
        inputs = [
            raw_process_wrapper_wrapper_output,
        ],
        outputs = [
            outputs.human.out,
            outputs.human.exit_code,
            outputs.machine.exit_code,
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

    raw_output = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_process_wrapper_wrapper_output_human"))
    raw_rustc_json_diagnostics = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "rustc_json_diagnostics"))

    rust_clippy_action.action(
        ctx,
        clippy_executable = clippy_bin,
        process_wrapper = ctx.executable._process_wrapper_wrapper,
        crate_info = crate_info,
        config = ctx.file._config_file,
        output = raw_output,
        cap_at_warnings = False,
        extra_clippy_flags = extra_options,
        clippy_diagnostics_file = raw_rustc_json_diagnostics,
    )

    _parse_wrapper_output_into_files(ctx, outputs, raw_output)
    _parse_to_sarif_action(ctx, _MNEMONIC, raw_rustc_json_diagnostics, outputs.machine.out)

    return [info]

def _parse_to_sarif_action(ctx, mnemonic, rustc_diagnostics_file, sarif_output):
    args = [
        "sarif",
        rustc_diagnostics_file.path,
        sarif_output.path,
    ]

    # Must be set for js_binary to run.
    # Ref: https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155?tab=readme-ov-file#running-nodejs-programs
    env = {
        "BAZEL_BINDIR": ".",
    }
    ctx.actions.run(
        executable = ctx.executable._rustc_sarif_parser,
        arguments = args,
        inputs = [rustc_diagnostics_file],
        outputs = [sarif_output],
        env = env,
    )

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
        "_rustc_sarif_parser": attr.label(
            doc = """A binary that can convert JSON rustc diagnostics into SARIF.

Note that rustc diagnostics are different from cargo diagnostics, which is what common rust implementations like sarif-rs use.
In particular, cargo diagnostics _may contain_ rustc diagnostics, but they don't have to.

References:
- Rustc diagnostic format: https://doc.rust-lang.org/beta/rustc/json.html#diagnostics
""",
            default = Label("//lint/rust:cli"),
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
