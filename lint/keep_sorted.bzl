"""API for declaring a keep-sorted lint aspect that visits all source files.

Typical usage:

First, fetch the keep-sorted dependency via gazelle

Then, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
go_deps = use_extension("@gazelle//:extensions.bzl", "go_deps")
go_deps.from_file(go_mod = "//:go.mod")
use_repo(go_deps, "com_github_google_keep_sorted")
```

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:keep_sorted.bzl", "lint_keep_sorted_aspect")


keep_sorted = lint_keep_sorted_aspect(
    binary = "@com_github_google_keep_sorted//:keep-sorted",
)
```
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "noop_lint_action", "output_files")

_MNEMONIC = "AspectRulesLintKeepSorted"

def keep_sorted_action(ctx, executable, srcs, stdout, exit_code = None, options = []):
    """Run keep-sorted as an action under Bazel.

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the keep-sorted program
        srcs: files to be linted
        stdout: output file containing stdout
        exit_code: output file containing exit code
            If None, then fail the build when program exits non-zero.
        options: additional command-line options
    """
    inputs = srcs
    outputs = [stdout]

    # Wire command-line options, see
    # Flags:
    # --color string              Whether to color debug output. One of "always", "never", or "auto" (default "auto")
    # --default-options options   The options keep-sorted will use to sort. Per-block overrides apply on top of these options. Note: list options like prefix_order are not merged with per-block overrides. They are completely overridden. (default allow_yaml_lists=yes case=yes group=yes remove_duplicates=yes sticky_comments=yes)
    # --lines line_ranges         Line ranges of the form "start:end". Only processes keep-sorted blocks that overlap with the given line ranges. Can only be used when fixing a single file. This flag can either be a comma-separated list of line ranges, or it can be specified multiple times on the command line to specify multiple line ranges. (default [])
    # --mode mode                 Determines what mode to run this tool in. One of ["fix" "lint"] (default fix)
    # -v, --verbose count             Log more verbosely
    # --version                   Report the keep-sorted version.
    args = ctx.actions.args()
    args.add_all(options)
    args.add("--mode=lint")
    args.add_all(srcs)
    
    if exit_code:
        command = "asd{keep_sorted} $@ >{stdout}; echo $? > " + exit_code.path
        outputs.append(exit_code)
    else:
        # Create empty stdout file on success, as Bazel expects one
        command = "{keep_sorted} $@ && touch {stdout}"

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        tools = [executable],
        command = command.format(keep_sorted = executable.path, stdout = stdout.path),
        arguments = [args],
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with KeepSorted",
    )

def _keep_sorted_aspect_impl(target, ctx):

    outputs, info = output_files(_MNEMONIC, target, ctx)

    if not hasattr(ctx.rule.attr, "srcs"):
        noop_lint_action(ctx, outputs)
        return [info]

    files_to_lint = filter_srcs(ctx.rule)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    color_options = ["--color=always"] if ctx.attr._options[LintOptionsInfo].color else []
    keep_sorted_action(ctx, ctx.executable._keep_sorted, files_to_lint, outputs.human.out, outputs.human.exit_code, color_options)
    keep_sorted_action(ctx, ctx.executable._keep_sorted, files_to_lint, outputs.machine.out, outputs.machine.exit_code)
    return [info]

def lint_keep_sorted_aspect(binary):
    """A factory function to create a linter aspect.

    Args:
        binary: a keep-sorted executable

    Returns:
        An aspect definition for keep-sorted
    """
    return aspect(
        implementation = _keep_sorted_aspect_impl,
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_keep_sorted": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
        },
        toolchains = [
        ],
    )
