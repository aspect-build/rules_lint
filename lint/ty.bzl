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

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "should_visit")
load(":ty_versions.bzl", "TY_VERSIONS")

_MNEMONIC = "AspectRulesLintTy"

def ty_action(ctx, executable, srcs, transitive_srcs, config, stdout, exit_code = None, env = {}):
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
    """
    inputs = depset(srcs + config, transitive = [transitive_srcs])
    outputs = [stdout]

    # Wire command-line options, see
    # `ty help check` to see available options
    args = ctx.actions.args()
    args.add("check")

    # Add all source files to be linted
    args.add_all(srcs)

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

# Provider to propagate transitive Python sources through the aspect graph
TyTransitiveSourcesInfo = provider(
    doc = "Transitive Python sources needed for type checking",
    fields = {
        "transitive_sources": "depset of Python source files",
    },
)

# buildifier: disable=function-docstring
def _ty_aspect_impl(target, ctx):
    # Collect transitive sources from dependencies first (always do this)
    # This ensures the provider chain is not broken even for non-linted targets
    transitive_sources = []

    # Collect from deps attribute
    if hasattr(ctx.rule.attr, "deps"):
        for dep in ctx.rule.attr.deps:
            if TyTransitiveSourcesInfo in dep:
                transitive_sources.append(dep[TyTransitiveSourcesInfo].transitive_sources)

    # When srcs contains labels to other targets (e.g., genrules that produce .py files),
    # we need to collect their transitive sources for proper type resolution
    if hasattr(ctx.rule.attr, "srcs"):
        for src in ctx.rule.attr.srcs:
            if TyTransitiveSourcesInfo in src:
                transitive_sources.append(src[TyTransitiveSourcesInfo].transitive_sources)

    # If this target shouldn't be linted, propagate collected sources anyway
    if not should_visit(ctx.rule, ctx.attr._rule_kinds, ctx.attr._filegroup_tags):
        return [
            TyTransitiveSourcesInfo(transitive_sources = depset(transitive = transitive_sources)),
        ]

    files_to_lint = filter_srcs(ctx.rule)
    outputs, info = output_files(_MNEMONIC, target, ctx)

    # Add current target's sources to the transitive set
    transitive_sources_depset = depset(
        files_to_lint,
        transitive = transitive_sources,
    )

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [
            info,
            TyTransitiveSourcesInfo(transitive_sources = transitive_sources_depset),
        ]

    color_env = {"FORCE_COLOR": "1"} if ctx.attr._options[LintOptionsInfo].color else {}

    # Pass transitive sources to ty_action so ty can resolve imports from dependencies
    transitive_only = depset(transitive = transitive_sources)
    ty_action(ctx, ctx.executable._ty, files_to_lint, transitive_only, ctx.files._config_file, outputs.human.out, outputs.human.exit_code, env = color_env)

    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    ty_action(ctx, ctx.executable._ty, files_to_lint, transitive_only, ctx.files._config_file, raw_machine_report, outputs.machine.exit_code)

    # Ideally we'd just use {"TY_OUTPUT_FORMAT": "sarif"} however it prints absolute paths; see https://github.com/astral-sh/ruff/issues/14985
    # This issue should also be resolved when the issue from ruff is fixed.
    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)

    return [
        info,
        TyTransitiveSourcesInfo(transitive_sources = transitive_sources_depset),
    ]

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
        # Propagate the aspect to dependencies and srcs so we can collect transitive sources
        # - deps: collects sources from py_library dependencies
        # - srcs: collects sources from generated Python files (e.g., from genrules)
        attr_aspects = ["deps", "srcs"],
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
            "_patcher": attr.label(
                default = "@aspect_rules_lint//lint/private:patcher",
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
