"""API for declaring a keep-sorted lint aspect that visits all source files.

Typical usage:

First, fetch the keep-sorted dependency via gazelle. We provide a convenient go.mod file.
To keep it isolated from your other go dependencies, we recommend adding to .bazelrc:

    common --experimental_isolated_extension_usages

Next add to MODULE.bazel:

    keep_sorted_deps = use_extension("@gazelle//:extensions.bzl", "go_deps", isolate = True)
    keep_sorted_deps.from_file(go_mod = "@aspect_rules_lint//lint/keep-sorted:go.mod")
    use_repo(keep_sorted_deps, "com_github_google_keep_sorted")

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:keep_sorted.bzl", "lint_keep_sorted_aspect")

keep_sorted = lint_keep_sorted_aspect(
    binary = Label("@com_github_google_keep_sorted//:keep-sorted"),
)
```

Now you can add `// keep-sorted start` / `// keep-sorted end` lines to your library sources,
following the documentation at https://github.com/google/keep-sorted#usage.
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "noop_lint_action", "output_files", "patch_and_output_files")
load("//lint/private:patcher_action.bzl", "patcher_attrs", "run_patcher")

_MNEMONIC = "AspectRulesLintKeepSorted"

def keep_sorted_action(ctx, executable, srcs, stdout, exit_code = None, options = [], patch = None):
    """Run keep-sorted as an action under Bazel.

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the keep-sorted program
        srcs: files to be linted
        stdout: output file containing stdout
        exit_code: output file containing exit code
            If None, then fail the build when program exits non-zero.
        options: additional command-line options
        patch: output file for patch (optional). If provided, uses run_patcher instead of run_shell.
    """
    inputs = srcs
    if patch != None:
        # Use run_patcher for fix mode
        args_list = options + ["--mode=fix"] + [s.path for s in srcs]
        run_patcher(
            ctx,
            ctx.executable,
            inputs = inputs,
            args = args_list,
            files_to_diff = [s.path for s in srcs],
            patch_out = patch,
            tools = [executable],
            stdout = stdout,
            exit_code = exit_code,
            mnemonic = _MNEMONIC,
            progress_message = "Fixing %{label} with KeepSorted",
            patch_cfg_suffix = "keep-sorted.patch_cfg",
        )
    else:
        # Use run_shell for lint mode
        outputs = [stdout]
        args = ctx.actions.args()
        args.add_all(options)
        args.add("--mode=lint")
        args.add_all(srcs)

        if exit_code:
            command = "{keep_sorted} $@ >{stdout}; echo $? > " + exit_code.path
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
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    if not hasattr(ctx.rule.attr, "srcs"):
        noop_lint_action(ctx, outputs)
        return [info]

    files_to_lint = filter_srcs(ctx.rule)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    color_options = ["--color=always"] if ctx.attr._options[LintOptionsInfo].color else []
    keep_sorted_action(
        ctx,
        ctx.executable._keep_sorted,
        files_to_lint,
        outputs.human.out,
        outputs.human.exit_code,
        options = color_options,
        patch = getattr(outputs, "patch", None),
    )
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
        attrs = patcher_attrs | {
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
