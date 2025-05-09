"""API for declaring a Ruff lint aspect that visits py_library rules.

Typical usage:

```
load("@aspect_rules_lint//lint:ruff.bzl", "ruff_aspect")

ruff = ruff_aspect(
    binary = "@multitool//tools/ruff",
    configs = "@@//:.ruff.toml",
)
```

## Using a specific ruff version

In `WORKSPACE`, fetch the desired version from https://github.com/astral-sh/ruff/releases

```starlark
load("@aspect_rules_lint//lint:ruff.bzl", "fetch_ruff")

# Specify a tag from the ruff repository
fetch_ruff("v0.4.10")
```

In `tools/lint/BUILD.bazel`, select the tool for the host platform:

```starlark
# Note: this won't interact properly with the --platform flag, see
# https://github.com/aspect-build/rules_lint/issues/389
alias(
    name = "ruff",
    actual = select({
        "@bazel_tools//src/conditions:linux_x86_64": "@ruff_x86_64-unknown-linux-gnu//:ruff",
        "@bazel_tools//src/conditions:linux_aarch64": "@ruff_aarch64-unknown-linux-gnu//:ruff",
        "@bazel_tools//src/conditions:darwin_arm64": "@ruff_aarch64-apple-darwin//:ruff",
        "@bazel_tools//src/conditions:darwin_x86_64": "@ruff_x86_64-apple-darwin//:ruff",
        "@bazel_tools//src/conditions:windows_x64": "@ruff_x86_64-pc-windows-msvc//:ruff.exe",
    }),
)
```

Finally, reference this tool alias rather than the one from `@multitool`:

```starlark
ruff = lint_ruff_aspect(
    binary = "@@//tools/lint:ruff",
    ...
)
```
"""

load("@bazel_skylib//lib:versions.bzl", "versions")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "patch_and_output_files", "should_visit")
load(":ruff_versions.bzl", "RUFF_VERSIONS")

_MNEMONIC = "AspectRulesLintRuff"
_OUTFILE_FORMAT = "{label}.{mnemonic}.{suffix}"

def ruff_action(ctx, executable, srcs, config, stdout, exit_code = None, env = {}):
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
        env: environment variaables for ruff
    """
    inputs = srcs + config
    outputs = [stdout]

    # Wire command-line options, see
    # `ruff help check` to see available options
    args = ctx.actions.args()
    args.add("check")

    # Honor exclusions in pyproject.toml even though we pass explicit list of files
    args.add("--force-exclude")
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
        env = env,
        progress_message = "Linting %{label} with Ruff",
        tools = [executable],
    )

def ruff_fix(ctx, executable, srcs, config, patch, stdout, exit_code, env = {}):
    """Create a Bazel Action that spawns ruff with --fix.

    Args:
        ctx: an action context OR aspect context
        executable: struct with _ruff and _patcher field
        srcs: list of file objects to lint
        config: labels of ruff config files (pyproject.toml, ruff.toml, or .ruff.toml)
        patch: output file containing the applied fixes that can be applied with the patch(1) command.
        stdout: output file of linter results to generate
        exit_code: output file to write the exit code
        env: environment variaables for ruff
    """
    patch_cfg = ctx.actions.declare_file("_{}.patch_cfg".format(ctx.label.name))

    ctx.actions.write(
        output = patch_cfg,
        content = json.encode({
            "linter": executable._ruff.path,
            "args": ["check", "--fix", "--force-exclude"] + [s.path for s in srcs],
            "files_to_diff": [s.path for s in srcs],
            "output": patch.path,
        }),
    )

    ctx.actions.run(
        inputs = srcs + config + [patch_cfg],
        outputs = [patch, exit_code, stdout],
        executable = executable._patcher,
        arguments = [patch_cfg.path],
        env = dict(env, **{
            "BAZEL_BINDIR": ".",
            "JS_BINARY__EXIT_CODE_OUTPUT_FILE": exit_code.path,
            "JS_BINARY__STDOUT_OUTPUT_FILE": stdout.path,
            "JS_BINARY__SILENT_ON_SUCCESS": "1",
        }),
        tools = [executable._ruff],
        mnemonic = _MNEMONIC,
        progress_message = "Fixing %{label} with Ruff",
    )

# buildifier: disable=function-docstring
def _ruff_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []

    files_to_lint = filter_srcs(ctx.rule)
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    color_env = {"FORCE_COLOR": "1"} if ctx.attr._options[LintOptionsInfo].color else {}

    # Ruff can produce a patch at the same time as reporting the unpatched violations
    if hasattr(outputs, "patch"):
        ruff_fix(ctx, ctx.executable, files_to_lint, ctx.files._config_files, outputs.patch, outputs.human.out, outputs.human.exit_code, env = color_env)
    else:
        ruff_action(ctx, ctx.executable._ruff, files_to_lint, ctx.files._config_files, outputs.human.out, outputs.human.exit_code, env = color_env)

    # TODO(alex): if we run with --fix, this will report the issues that were fixed. Does a machine reader want to know about them?
    raw_machine_report = ctx.actions.declare_file(_OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    ruff_action(ctx, ctx.executable._ruff, files_to_lint, ctx.files._config_files, raw_machine_report, outputs.machine.exit_code)

    # Ideally we'd just use {"RUFF_OUTPUT_FORMAT": "sarif"} however it prints absolute paths; see https://github.com/astral-sh/ruff/issues/14985
    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)

    return [info]

def lint_ruff_aspect(binary, configs, rule_kinds = ["py_binary", "py_library", "py_test"]):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a ruff executable
        configs: ruff config file(s) (`pyproject.toml`, `ruff.toml`, or `.ruff.toml`)
        rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect
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
            "_sarif": attr.label(
                default = "@aspect_rules_lint//tools/sarif/cmd/sarif",
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
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
    )

def _ruff_workaround_20269_impl(rctx):
    # download_and_extract has a bug due to the use of Apache Commons library within Bazel,
    # See https://github.com/bazelbuild/bazel/issues/20269
    # To workaround, we fetch the file and then use the BSD tar on the system to extract it.
    rctx.download(sha256 = rctx.attr.sha256, url = rctx.attr.url, output = "ruff.tar.gz")
    tar_cmd = [rctx.which("tar"), "xzf", "ruff.tar.gz"]
    if rctx.attr.strip_prefix:
        tar_cmd.append("--strip-components=1")
    result = rctx.execute(tar_cmd)
    if result.return_code:
        fail("Couldn't extract ruff: \nSTDOUT:\n{}\nSTDERR:\n{}".format(result.out, result.stderr))
    rctx.file("BUILD", rctx.attr.build_file_content)

ruff_workaround_20269 = repository_rule(
    _ruff_workaround_20269_impl,
    doc = "Workaround for https://github.com/bazelbuild/bazel/issues/20269",
    attrs = {
        "build_file_content": attr.string(),
        "sha256": attr.string(),
        "strip_prefix": attr.string(doc = "unlike http_archive, any value causes us to pass --strip-components=1 to tar"),
        "url": attr.string(),
    },
)

def fetch_ruff(tag):
    """A repository macro used from WORKSPACE to fetch ruff binaries.

    Allows the user to select a particular ruff version, rather than get whatever is pinned in the `multitool.lock.json` file.

    Args:
        tag: a tag of ruff that we have mirrored, e.g. `v0.1.0`
    """
    version = tag.lstrip("v")

    # ruff changed their release artifact naming starting with v0.1.8, so that's the minimum version we support
    # they changed it again in 0.5.0, removing the version from the filename.
    if versions.is_at_least("0.5.0", version):
        url = "https://github.com/astral-sh/ruff/releases/download/{tag}/ruff-{plat}.{ext}"
    else:
        url = "https://github.com/astral-sh/ruff/releases/download/{tag}/ruff-{version}-{plat}.{ext}"

    for plat, sha256 in RUFF_VERSIONS[tag].items():
        fetch_rule = http_archive
        if plat.endswith("darwin") and not versions.is_at_least("7.2.0", versions.get()):
            fetch_rule = ruff_workaround_20269
        is_windows = plat.endswith("windows-msvc")

        # Account for ruff packaging change in 0.5.0
        strip_prefix = None
        if versions.is_at_least("0.5.0", version) and not is_windows:
            strip_prefix = "ruff-" + plat

        maybe(
            fetch_rule,
            name = "ruff_" + plat,
            url = url.format(
                tag = tag,
                plat = plat,
                version = version,
                ext = "zip" if is_windows else "tar.gz",
            ),
            strip_prefix = strip_prefix,
            sha256 = sha256,
            build_file_content = """exports_files(["ruff", "ruff.exe"])""",
        )
