"""API for declaring a Ty lint aspect that visits py_{binary|library|test} rules.

Typical usage:

Ty is provided as a built-in tool by rules_lint. To use the built-in version,
create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:ty.bzl", "lint_ty_aspect")

ty = lint_ty_aspect(
    binary = Label("@aspect_rules_lint//lint:ty_bin"),
    config = Label("//:ty.toml"),
)
```
"""

load("@rules_python//python:defs.bzl", "PyInfo")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "should_visit")

_MNEMONIC = "AspectRulesLintTy"

def ty_action(ctx, executable, srcs, transitive_srcs, config, stdout, exit_code = None, env = {}, extra_search_paths = []):
    """Run ty as an action under Bazel.

    ty supports persistent configuration files at both the project- and user-level
    as documented here: https://docs.astral.sh/ty/configuration/

    Note: all config files are passed to the action.
    This means that a change to any config file invalidates the action cache entries for ALL
    ty actions.

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the ty program
        srcs: python files to be linted
        transitive_srcs: depset of transitive Python sources from dependencies
        config: labels of ty config files (pyproject.toml, ty.toml)
        stdout: output file of linter results to generate
        exit_code: output file to write the exit code.
            If None, then fail the build when ty exits non-zero.
            https://docs.astral.sh/ty/reference/exit-codes/
        env: environment variables for ty
        extra_search_paths: list of paths to add as --extra-search-path for third-party module resolution
    """
    inputs = depset(srcs + config, transitive = [transitive_srcs])
    outputs = [stdout]

    # Wire command-line options, see
    # `ty help check` to see available options
    args = ctx.actions.args()
    args.add("check")

    # Add all source files to be linted
    args.add_all(srcs)

    # Add extra search paths for third-party dependencies (pip packages)
    for path in extra_search_paths:
        args.add("--extra-search-path", path)

    ## Ty's color output is turned off for non-interactive invocations
    args.add("--color", "always")

    if exit_code:
        command = "{ty} $@ >{stdout}; echo $? >" + exit_code.path
        outputs.append(exit_code)
    else:
        # Create empty file on success, as Bazel expects one
        command = "{ty} $@ && touch {stdout}"

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        command = command.format(ty = executable.path, stdout = stdout.path),
        arguments = [args],
        mnemonic = _MNEMONIC,
        env = env,
        progress_message = "Linting %{label} with ty",
        tools = [executable],
    )

# buildifier: disable=function-docstring
def _ty_aspect_impl(target, ctx):
    # Collect transitive sources from dependencies using the standard PyInfo provider.
    transitive_sources = []

    # Collect import paths from PyInfo for third-party dependencies (pip packages).
    # These paths are used with --extra-search-path to help ty find external modules.
    # Import paths from pip packages look like "rules_python~~pip~pip_39_pathspec/site-packages"
    # and need to be prefixed with "external/" to form the actual path in the execroot.
    import_paths = {}

    # Collect from deps attribute using PyInfo
    if hasattr(ctx.rule.attr, "deps"):
        for dep in ctx.rule.attr.deps:
            if PyInfo in dep:
                transitive_sources.append(dep[PyInfo].transitive_sources)

                # Collect imports from pip packages for extra search paths
                for import_path in dep[PyInfo].imports.to_list():
                    #if import_path != ctx.workspace_name:
                    import_paths["external/" + import_path] = True

    # When srcs contain labels to other targets (e.g., genrules that produce .py files),
    # we need to collect their transitive sources for proper type resolution
    if hasattr(ctx.rule.attr, "srcs"):
        for src in ctx.rule.attr.srcs:
            if PyInfo in src:
                transitive_sources.append(src[PyInfo].transitive_sources)
                for import_path in src[PyInfo].imports.to_list():
                    import_paths["external/" + import_path] = True

    if not should_visit(ctx.rule, ctx.attr._rule_kinds, ctx.attr._filegroup_tags):
        return []

    files_to_lint = filter_srcs(ctx.rule)
    outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    color_env = {"FORCE_COLOR": "1"} if ctx.attr._options[LintOptionsInfo].color else {}

    # Pass transitive sources to ty_action so ty can resolve imports from dependencies
    transitive_srcs_depset = depset(transitive = transitive_sources)
    extra_search_paths = import_paths.keys()
    ty_action(ctx, ctx.executable._ty, files_to_lint, transitive_srcs_depset, ctx.files._config_file, outputs.human.out, outputs.human.exit_code, env = color_env, extra_search_paths = extra_search_paths)

    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    ty_action(ctx, ctx.executable._ty, files_to_lint, transitive_srcs_depset, ctx.files._config_file, raw_machine_report, outputs.machine.exit_code, extra_search_paths = extra_search_paths)

    # Ideally we'd just use {"TY_OUTPUT_FORMAT": "sarif"} however it prints absolute paths; see https://github.com/astral-sh/ruff/issues/14985
    # This issue should also be resolved when the issue from ruff is fixed.
    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)

    return [info]

def lint_ty_aspect(binary, config, rule_kinds = ["py_binary", "py_library", "py_test"], filegroup_tags = ["python", "lint-with-ty"]):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a ty executable
        configs: ty config file(s) (`pyproject.toml`, `ty.toml`)
        rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect
        filegroup_tags: filegroups tagged with these tags will be visited by the aspect in addition to Python rule kinds
    """

    return aspect(
        implementation = _ty_aspect_impl,
        # Propagate the aspect to dependencies so they are also linted.
        # Transitive sources for type resolution are obtained via PyInfo provider.
        attr_aspects = ["deps"],
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_ty": attr.label(
                default = binary,
                allow_files = True,
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(
                default = config,
                allow_files = True,
            ),
            "_filegroup_tags": attr.string_list(
                default = filegroup_tags,
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
        toolchains = [OPTIONAL_SARIF_PARSER_TOOLCHAIN],
    )
