"""API for declaring a SwiftLint lint aspect for Swift sources.

Typical usage:

Fetch SwiftLint with the shared lint tools extension in `MODULE.bazel`:

```starlark
lint_tools = use_extension("@aspect_rules_lint//lint:extensions.bzl", "tools")
lint_tools.swiftlint()
use_repo(lint_tools, "swiftlint_binary")
```

Then, create an alias in `tools/lint/BUILD.bazel`:

```starlark
alias(
    name = "swiftlint",
    actual = "@swiftlint_binary//:swiftlint",
)
```

Then, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:swiftlint.bzl", "lint_swiftlint_aspect")

swiftlint = lint_swiftlint_aspect(
    binary = Label("//tools/lint:swiftlint"),
    configs = [Label("//:.swiftlint.yml")],
)
```

Config files passed in `configs` are declared action inputs and forwarded to
SwiftLint with `--config`, so SwiftLint does not auto-discover undeclared
repository config files. Pass `configs = []` only when no repository
`.swiftlint.yml` should affect the action; rules_lint will pass an empty config
file so SwiftLint still uses its built-in rule defaults.

Set `config_mode = "nested"` to use target-specific nested `.swiftlint.yml`
files. In nested mode, rules_lint selects the main config plus the deepest child
config containing all Swift source files in the target, matching SwiftLint's
nearest nested config behavior.

Declare SwiftLint configuration hierarchy files in `configs`. Prefer the
`baseline` argument over a `baseline` entry in `.swiftlint.yml`. Do not use
`write_baseline`, remote config URLs, or `check_for_updates` in Bazel actions
because they introduce undeclared writes, network access, or both.

Bazel target membership determines the files linted by this aspect. SwiftLint's
`excluded` configuration is still honored because rules_lint passes
`--force-exclude`, but `included` is not a reliable way to narrow explicitly
passed Bazel source files.

SwiftLint policy should generally live in `.swiftlint.yml`. The aspect only
exposes CLI options that affect Bazel execution behavior or action inputs.
Machine-readable reports always use SwiftLint's SARIF reporter.
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "noop_lint_action", "output_files", "patch_and_output_files", "should_visit")
load("//lint/private:patcher_action.bzl", "patcher_attrs", "run_patcher")

_MNEMONIC = "AspectRulesLintSwiftLint"
_EMPTY_CONFIG = Label("//lint:empty_swiftlint.yml")
_CONFIG_MODE_EXPLICIT = "explicit"
_CONFIG_MODE_NESTED = "nested"
_CONFIG_MODES = [_CONFIG_MODE_EXPLICIT, _CONFIG_MODE_NESTED]

def _swift_srcs(rule):
    return [src for src in filter_srcs(rule) if src.path.endswith(".swift")]

def _config_args(configs):
    args = []
    for config in configs:
        args.extend(["--config", config.path])
    return args

def _dirname(path):
    parts = path.split("/")
    if len(parts) == 1:
        return ""
    return "/".join(parts[:-1])

def _path_is_under_dir(path, directory):
    return directory == "" or path == directory or path.startswith(directory + "/")

def _format_file_paths(files):
    return "[{}]".format(", ".join([f.path for f in files]))

def _same_file_paths(a, b):
    if len(a) != len(b):
        return False
    for i in range(len(a)):
        if a[i].path != b[i].path:
            return False
    return True

def _nested_configs_for_src(configs, src):
    if not configs:
        return []

    selected = [configs[0]]
    src_dir = _dirname(src.path)
    selected_child = None
    selected_child_dir_len = -1
    for config in configs[1:]:
        config_dir = _dirname(config.path)
        if _path_is_under_dir(src_dir, config_dir) and len(config_dir) > selected_child_dir_len:
            selected_child = config
            selected_child_dir_len = len(config_dir)

    if selected_child != None:
        selected.append(selected_child)
    return selected

def _nested_configs_for_srcs(configs, srcs, label):
    if not srcs:
        return configs

    selected = _nested_configs_for_src(configs, srcs[0])
    for src in srcs[1:]:
        src_configs = _nested_configs_for_src(configs, src)
        if not _same_file_paths(selected, src_configs):
            fail("""SwiftLint nested config mode requires all Swift files in a Bazel target to use the same config hierarchy.
Target {label} selects {selected} for {first_src}, but {src} selects {src_configs}.
Split those Swift files into separate Bazel targets, or use config_mode = "explicit".""".format(
                label = label,
                selected = _format_file_paths(selected),
                first_src = srcs[0].path,
                src = src.path,
                src_configs = _format_file_paths(src_configs),
            ))
    return selected

def _effective_configs(configs, srcs, config_mode, label):
    if config_mode == _CONFIG_MODE_NESTED:
        return _nested_configs_for_srcs(configs, srcs, label)
    return configs

def _baseline_args(baseline):
    if not baseline:
        return []
    if len(baseline) > 1:
        fail("SwiftLint accepts at most one baseline file")
    return ["--baseline", baseline[0].path]

def _swiftlint_options(quiet, reporter, baseline):
    args = [
        "--force-exclude",
        "--no-cache",
    ]

    if quiet:
        args.append("--quiet")
    if reporter:
        args.extend(["--reporter", reporter])

    args.extend(_baseline_args(baseline))

    return args

def swiftlint_action(
        ctx,
        executable,
        srcs,
        configs,
        stdout,
        exit_code = None,
        reporter = None,
        quiet = True,
        baseline = None,
        config_mode = _CONFIG_MODE_EXPLICIT,
        patch = None):
    """Run SwiftLint as an action under Bazel.

    Based on the official SwiftLint CLI:
    https://github.com/realm/SwiftLint

    Args:
        ctx: Bazel rule or aspect evaluation context.
        executable: the SwiftLint executable.
        srcs: Swift source files to lint.
        configs: SwiftLint config files available to the action.
        stdout: output file containing linter output.
        exit_code: optional output file containing the linter exit code.
        reporter: SwiftLint reporter to use.
        quiet: whether to suppress SwiftLint status logs.
        baseline: optional SwiftLint baseline file.
        config_mode: `explicit` passes configs as `--config`; `nested` selects
            the main config and target-specific child config from configs, then
            passes the selected hierarchy as `--config`.
        patch: optional patch file output when running in fix mode.
    """
    if baseline == None:
        baseline = []

    configs = _effective_configs(configs, srcs, config_mode, ctx.label)
    inputs = srcs + configs + baseline
    config_args = _config_args(configs)

    lint_args = _swiftlint_options(
        quiet,
        reporter,
        baseline,
    ) + config_args + [src.path for src in srcs]

    if patch != None:
        wrapper = ctx.actions.declare_file(ctx.label.name + ".swiftlint_wrapper.sh")
        ctx.actions.write(
            output = wrapper,
            content = """#!/bin/bash
tmp=$(mktemp)
"{swiftlint}" lint --fix "$@" >/dev/null 2>&1 || true
"{swiftlint}" lint "$@" >"$tmp" 2>&1
status=$?
sed "s|$PWD/||g" "$tmp"
rm "$tmp"
exit $status
""".format(swiftlint = executable.path),
            is_executable = True,
        )

        run_patcher(
            ctx,
            ctx.executable,
            inputs = inputs,
            args = lint_args,
            files_to_diff = [src.path for src in srcs],
            patch_out = patch,
            tools = [wrapper, executable],
            stdout = stdout,
            exit_code = exit_code,
            mnemonic = _MNEMONIC,
            progress_message = "Fixing %{label} with SwiftLint",
        )
        return

    outputs = [stdout]
    args = ctx.actions.args()
    args.add("lint")
    args.add_all(lint_args)

    if exit_code:
        command = """
tmp=$(mktemp)
"{swiftlint}" "$@" >"$tmp" 2>&1
status=$?
sed "s|$PWD/||g" "$tmp" >{stdout}
rm "$tmp"
echo $status > {exit_code}
""".format(
            swiftlint = executable.path,
            stdout = stdout.path,
            exit_code = exit_code.path,
        )
        outputs.append(exit_code)
    else:
        command = """
tmp=$(mktemp)
"{swiftlint}" "$@" >"$tmp" 2>&1
status=$?
sed "s|$PWD/||g" "$tmp" >{stdout}
rm "$tmp"
exit $status
""".format(
            swiftlint = executable.path,
            stdout = stdout.path,
        )

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        command = command,
        arguments = [args],
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with SwiftLint",
        tools = [executable],
    )

def _swiftlint_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds, ctx.attr._filegroup_tags):
        return []

    files_to_lint = _swift_srcs(ctx.rule)
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    swiftlint_action(
        ctx,
        ctx.executable._swiftlint,
        files_to_lint,
        ctx.files._config_files,
        outputs.human.out,
        outputs.human.exit_code,
        quiet = ctx.attr._quiet,
        baseline = ctx.files._baseline,
        config_mode = ctx.attr._config_mode,
        patch = getattr(outputs, "patch", None),
    )
    swiftlint_action(
        ctx,
        ctx.executable._swiftlint,
        files_to_lint,
        ctx.files._config_files,
        outputs.machine.out,
        outputs.machine.exit_code,
        reporter = "sarif",
        # SwiftLint prints status logs before reporter output unless quiet is
        # enabled, which would corrupt the machine-readable SARIF JSON.
        quiet = True,
        baseline = ctx.files._baseline,
        config_mode = ctx.attr._config_mode,
    )

    return [info]

def lint_swiftlint_aspect(
        binary,
        configs,
        quiet = True,
        baseline = None,
        config_mode = _CONFIG_MODE_EXPLICIT,
        rule_kinds = ["swift_binary", "swift_compiler_plugin", "swift_library", "swift_test"],
        filegroup_tags = ["swift", "lint-with-swiftlint"]):
    """Create a SwiftLint linter aspect.

    Args:
        binary: a SwiftLint executable, for example `//tools/lint:swiftlint`.
        configs: SwiftLint config files to pass as action inputs. Pass an empty
            list only when repository config files should not be used.
        quiet: pass `--quiet`, suppressing SwiftLint status logs. Defaults to
            True because SwiftLint writes status logs into report outputs.
        baseline: optional SwiftLint baseline file. Prefer this over a
            `baseline` entry in `.swiftlint.yml` so Bazel can declare the file
            as an action input.
        config_mode: `explicit` passes every `configs` entry to every target.
            `nested` selects the main config and nearest target-specific child
            config.
        rule_kinds: which rule kinds should be visited automatically.
        filegroup_tags: filegroup tags that opt targets into SwiftLint linting.

    Returns:
        An aspect definition for SwiftLint.
    """
    if type(configs) == "string":
        configs = [configs]
    if config_mode not in _CONFIG_MODES:
        fail("config_mode must be one of {}, got {}".format(_CONFIG_MODES, config_mode))
    if len(configs) == 0:
        configs = [_EMPTY_CONFIG]
    if baseline == None:
        baseline = []
    elif type(baseline) == "list":
        if len(baseline) > 1:
            fail("baseline accepts at most one label")
    else:
        baseline = [baseline]

    return aspect(
        implementation = _swiftlint_aspect_impl,
        attrs = patcher_attrs | {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_swiftlint": attr.label(
                default = binary,
                allow_files = True,
                executable = True,
                cfg = "exec",
            ),
            "_config_files": attr.label_list(
                default = configs,
                allow_files = True,
            ),
            "_quiet": attr.bool(
                default = quiet,
            ),
            "_baseline": attr.label_list(
                default = baseline,
                allow_files = True,
            ),
            "_config_mode": attr.string(
                default = config_mode,
            ),
            "_filegroup_tags": attr.string_list(
                default = filegroup_tags,
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
    )
