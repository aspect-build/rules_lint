"""API for declaring a Ruff lint aspect that visits py_library rules.

Typical usage:

```
load("@aspect_rules_lint//lint:ruff.bzl", "ruff_aspect")

ruff = ruff_aspect(
    binary = "@@//:ruff",
    configs = "@@//:.ruff.toml",
)
```
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "patch_and_report_files", "report_files")
load(":ruff_versions.bzl", "RUFF_VERSIONS")

_MNEMONIC = "ruff"

def ruff_action(ctx, executable, srcs, config, stdout, exit_code = None):
    """Run ruff as an action under Bazel.

    Ruff will select the configuration file to use for each source file, as documented here:
    https://docs.astral.sh/ruff/configuration/#config-file-discovery

    Note: all config files are passed to the action.
    This means that a change to any config file invalidates the action cache entries for ALL
    ruff actions.

    However this is needed because:

    1. ruff has an `extend` field, so it may need to read more than one config file
    2. ruff's logic for selecting the appropriate config needs to read the file content to detect
      a `[tool.ruff]` section.

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the ruff program
        srcs: python files to be linted
        config: labels of ruff config files (pyproject.toml, ruff.toml, or .ruff.toml)
        stdout: output file of linter results to generate
        exit_code: output file to write the exit code.
            If None, then fail the build when ruff exits non-zero.
            See https://github.com/astral-sh/ruff/blob/dfe4291c0b7249ae892f5f1d513e6f1404436c13/docs/linter.md#exit-codes
    """
    inputs = srcs + config
    outputs = [stdout]

    # Wire command-line options, see
    # `ruff help check` to see available options
    args = ctx.actions.args()
    args.add("check")
    args.add_all(srcs)

    if exit_code:
        command = "{ruff} $@ >{stdout}; echo $? >" + exit_code.path
        outputs.append(exit_code)
    else:
        # Create empty file on success, as Bazel expects one
        command = "{ruff} $@ && touch {stdout}"

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        command = command.format(ruff = executable.path, stdout = stdout.path),
        arguments = [args],
        mnemonic = _MNEMONIC,
        tools = [executable],
    )

def ruff_fix(ctx, executable, srcs, config, patch, stdout, exit_code):
    """Create a Bazel Action that spawns ruff with --fix.

    Args:
        ctx: an action context OR aspect context
        executable: struct with _ruff and _patcher field
        srcs: list of file objects to lint
        config: labels of ruff config files (pyproject.toml, ruff.toml, or .ruff.toml)
        patch: output file containing the applied fixes that can be applied with the patch(1) command.
        stdout: output file of linter results to generate
        exit_code: output file to write the exit code
    """
    patch_cfg = ctx.actions.declare_file("_{}.patch_cfg".format(ctx.label.name))

    ctx.actions.write(
        output = patch_cfg,
        content = json.encode({
            "linter": executable._ruff.path,
            "args": ["check", "--fix"] + [s.path for s in srcs],
            "files_to_diff": [s.path for s in srcs],
            "output": patch.path,
        }),
    )

    ctx.actions.run(
        inputs = srcs + config + [patch_cfg],
        outputs = [patch, exit_code, stdout],
        executable = executable._patcher,
        arguments = [patch_cfg.path],
        env = {
            "BAZEL_BINDIR": ".",
            "JS_BINARY__EXIT_CODE_OUTPUT_FILE": exit_code.path,
            "JS_BINARY__STDOUT_OUTPUT_FILE": stdout.path,
            "JS_BINARY__SILENT_ON_SUCCESS": "1",
        },
        tools = [executable._ruff],
        mnemonic = _MNEMONIC,
    )

# buildifier: disable=function-docstring
def _ruff_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["py_binary", "py_library", "py_test"]:
        return []

    files_to_lint = filter_srcs(ctx.rule)
    if ctx.attr._options[LintOptionsInfo].fix:
        patch, report, exit_code, info = patch_and_report_files(_MNEMONIC, target, ctx)
        ruff_fix(ctx, ctx.executable, files_to_lint, ctx.files._config_files, patch, report, exit_code)
    else:
        report, exit_code, info = report_files(_MNEMONIC, target, ctx)
        ruff_action(ctx, ctx.executable._ruff, files_to_lint, ctx.files._config_files, report, exit_code)
    return [info]

def lint_ruff_aspect(binary, configs):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a ruff executable
        configs: ruff config file(s) (`pyproject.toml`, `ruff.toml`, or `.ruff.toml`)
    """

    # syntax-sugar: allow a single config file in addition to a list
    if type(configs) == "string":
        configs = [configs]

    return aspect(
        implementation = _ruff_aspect_impl,
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_ruff": attr.label(
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
            "_config_files": attr.label_list(
                default = configs,
                allow_files = True,
            ),
        },
    )

def _ruff_workaround_20269_impl(rctx):
    # download_and_extract has a bug due to the use of Apache Commons library within Bazel,
    # See https://github.com/bazelbuild/bazel/issues/20269
    # To workaround, we fetch the file and then use the BSD tar on the system to extract it.
    # TODO: remove for users on Bazel 8 (or maybe sooner if that fix is cherry-picked)
    rctx.download(sha256 = rctx.attr.sha256, url = rctx.attr.url, output = "ruff.tar.gz")
    result = rctx.execute([rctx.which("tar"), "xzf", "ruff.tar.gz"])
    if result.return_code:
        fail("Couldn't extract ruff: \nSTDOUT:\n{}\nSTDERR:\n{}".format(result.stdout, result.stderr))
    rctx.file("BUILD", rctx.attr.build_file_content)

ruff_workaround_20269 = repository_rule(
    _ruff_workaround_20269_impl,
    doc = "Workaround for https://github.com/bazelbuild/bazel/issues/20269",
    attrs = {
        "build_file_content": attr.string(),
        "sha256": attr.string(),
        "url": attr.string(),
    },
)

def fetch_ruff(tag = RUFF_VERSIONS.keys()[0]):
    """A repository macro used from WORKSPACE to fetch ruff binaries

    Args:
        tag: a tag of ruff that we have mirrored, e.g. `v0.1.0`
    """
    version = tag.lstrip("v")

    # ruff changed their release artifact naming starting with v0.1.8, so that's the minimum version we support
    url = "https://github.com/astral-sh/ruff/releases/download/{tag}/ruff-{version}-{plat}.{ext}"

    for plat, sha256 in RUFF_VERSIONS[tag].items():
        fetch_rule = http_archive
        if plat.endswith("darwin"):
            fetch_rule = ruff_workaround_20269
        is_windows = plat.endswith("windows-msvc")

        maybe(
            fetch_rule,
            name = "ruff_" + plat,
            url = url.format(
                tag = tag,
                plat = plat,
                version = version,
                ext = "zip" if is_windows else "tar.gz",
            ),
            sha256 = sha256,
            build_file_content = """exports_files(["ruff", "ruff.exe"])""",
        )
