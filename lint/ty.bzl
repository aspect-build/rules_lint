"""API for declaring a Ty lint aspect that visits py_{binary|library|test} rules.

Typical usage:

Ty is provided as a built-in tool by rules_lint. To use the built-in version,
create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:ty.bzl", "lint_ty_aspect")

ty = lint_ty_aspect(
    binary = Label("@aspect_rules_lint//lint:ty_bin",
    config = Label("//:ty.toml"),
)
```

## Using a specific ty version

In `WORKSPACE`, fetch the desired version from https://github.com/astral-sh/ty/releases

```starlark
load("@aspect_rules_lint//lint:ty.bzl", "fetch_ty")

# Specify a tag from the ty repository
fetch_ty("v0.0.1-alpha.27")
```

In `tools/lint/BUILD.bazel`, select the tool for the host platform:

```starlark
# Note: this won't interact properly with the --platform flag, see
# https://github.com/aspect-build/rules_lint/issues/389
alias(
    name = "ty",
    actual = select({
        "@bazel_tools//src/conditions:linux_x86_64": "@ty_x86_64-unknown-linux-gnu//:ty",
        "@bazel_tools//src/conditions:linux_aarch64": "@ty_aarch64-unknown-linux-gnu//:ty",
        "@bazel_tools//src/conditions:darwin_arm64": "@ty_aarch64-apple-darwin//:ty",
        "@bazel_tools//src/conditions:darwin_x86_64": "@ty_x86_64-apple-darwin//:ty",
        "@bazel_tools//src/conditions:windows_x64": "@ty_x86_64-pc-windows-msvc//:ty.exe",
    }),
)
```

Finally, reference this tool alias rather than the one from `@multitool`:

```starlark
ty = lint_ty_aspect(
    binary = "@@//tools/lint:ty",
    ...
)
```
"""

load("@bazel_skylib//lib:versions.bzl", "versions")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "patch_and_output_files", "should_visit")
load(":ty_versions.bzl", "TY_VERSIONS")

_MNEMONIC = "AspectRulesLintTy"

def ty_action(ctx, executable, srcs, config, stdout, exit_code = None, env = {}):
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
        config: labels of ty config files (pyproject.toml, ty.toml)
        stdout: output file of linter results to generate
        exit_code: output file to write the exit code.
            If None, then fail the build when ty exits non-zero.
            https://docs.astral.sh/ty/reference/exit-codes/
        env: environment variables for ty
    """
    inputs = srcs + config
    outputs = [stdout]

    # Wire command-line options, see
    # `ty help check` to see available options
    args = ctx.actions.args()
    args.add("check")

    # Add all source files to be linted
    args.add_all(srcs)

    ## Ty's color output is turned off for non-interactive invocations
    args.add("--color always")

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
    if not should_visit(ctx.rule, ctx.attr._rule_kinds, ctx.attr._filegroup_tags):
        return []

    files_to_lint = filter_srcs(ctx.rule)
    outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    color_env = {"FORCE_COLOR": "1"} if ctx.attr._options[LintOptionsInfo].color else {}

    ty_action(ctx, ctx.executable._ty, files_to_lint, ctx.files._config_file, outputs.human.out, outputs.human.exit_code, env = color_env)

    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    ty_action(ctx, ctx.executable._ty, files_to_lint, ctx.files._config_file, raw_machine_report, outputs.machine.exit_code)

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

def _ty_workaround_20269_impl(rctx):
    # TODO: This workaround is copied from the ruff.bzl rules and should probably be shared.
    # download_and_extract has a bug due to the use of Apache Commons library within Bazel,
    # See https://github.com/bazelbuild/bazel/issues/20269
    # To workaround, we fetch the file and then use the BSD tar on the system to extract it.
    rctx.download(sha256 = rctx.attr.sha256, url = rctx.attr.url, output = "ty.tar.gz")
    tar_cmd = [rctx.which("tar"), "xzf", "ty.tar.gz"]
    if rctx.attr.strip_prefix:
        tar_cmd.append("--strip-components=1")
    result = rctx.execute(tar_cmd)
    if result.return_code:
        fail("Couldn't extract ty: \nSTDOUT:\n{}\nSTDERR:\n{}".format(result.out, result.stderr))
    rctx.file("BUILD", rctx.attr.build_file_content)

ty_workaround_20269 = repository_rule(
    _ty_workaround_20269_impl,
    doc = "Workaround for https://github.com/bazelbuild/bazel/issues/20269",
    attrs = {
        "build_file_content": attr.string(),
        "sha256": attr.string(),
        "strip_prefix": attr.string(doc = "unlike http_archive, any value causes us to pass --strip-components=1 to tar"),
        "url": attr.string(),
    },
)

def fetch_ty(tag):
    """A repository macro used from WORKSPACE to fetch ty binaries.

    Allows the user to select a particular ty version, rather than get whatever is pinned in the `multitool.lock.json` file.

    Args:
        tag: a tag of ty that we have mirrored, e.g. `v0.1.0`
    """
    version = tag.lstrip("v")
    url = "https://github.com/astral-sh/ty/releases/download/{tag}/ty-{version}-{plat}.{ext}"

    for plat, sha256 in TY_VERSIONS[tag].items():
        fetch_rule = http_archive
        if plat.endswith("darwin") and not versions.is_at_least("7.2.0", versions.get()):
            fetch_rule = ty_workaround_20269
        is_windows = plat.endswith("windows-msvc")

        # Account for ty packaging change in 0.5.0
        strip_prefix = None
        if versions.is_at_least("0.5.0", version) and not is_windows:
            strip_prefix = "ty-" + plat

        maybe(
            fetch_rule,
            name = "ty_" + plat,
            url = url.format(
                tag = tag,
                plat = plat,
                version = version,
                ext = "zip" if is_windows else "tar.gz",
            ),
            strip_prefix = strip_prefix,
            sha256 = sha256,
            build_file_content = """exports_files(["ty", "ty.exe"])""",
        )

