"""API for declaring a semgrep lint aspect that visits supported rules.

Typical usage:

First, fetch the semgrep package via your standard requirements file and pip calls.

Then, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

py_console_script_binary(
    name = "semgrep",
    script = "pysemgrep",
    pkg = "@pip//semgrep:pkg",
)
```

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:semgrep.bzl", "lint_semgrep_aspect")

semgrep = lint_semgrep_aspect(
    binary = Label("//tools/lint:semgrep"),
    config = Label("//:.semgreprc"),
)
```
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "should_visit")

_MNEMONIC = "AspectRulesLintSemgrep"
_BASE_OPTIONS = [
  "scan",
  "--quiet",
  "--strict",
  "--error",
]

def semgrep_action(ctx, executable, srcs, config, stdout, exit_code = None, env = {}, options = []):
    """Run semgrep as an action under Bazel.

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the semgrep program
        srcs: files to be linted
        config: label of the directory with semgrep rules (defaults to `auto`).
        stdout: output file containing stdout of semgrep
        exit_code: output file containing exit code of semgrep
            If None, then fail the build when semgrep exits non-zero.
        env: environment variables passed to the tool.
        options: additional command-line options
    """
    inputs = []
    if len(config) > 1:
        fail("config expects at most a single argument")
    if config:
        config_dir = config[0]
        inputs.append(config_dir)
    else:
        config_dir = "auto"
    inputs.extend(srcs)
    outputs = [stdout]

    args = ctx.actions.args()
    args.add(executable._semgrep.path)
    args.add_all(_BASE_OPTIONS)
    args.add_all(ctx.attr._extra_options)
    args.add(config_dir, format="--config=%s")
    args.add_all(options)
    args.add_all(srcs)

    _env = {}
    if exit_code:
        _env["RULES_LINT__SEMGREP__EXIT_CODE_FILE"] = exit_code.path
        outputs.append(exit_code)

    settings_file = ctx.actions.declare_file(stdout.path + "_settings.yaml")
    outputs.append(settings_file)
    log_file = ctx.actions.declare_file(stdout.path + "_log")
    outputs.append(log_file)

    # TODO patch mode with --autofix

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        tools = [executable._semgrep_wrapper, executable._semgrep],
        command =  "{semgrep} $@".format(semgrep=executable._semgrep_wrapper.path),
        arguments = [args],
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with semgrep",
        env = env | _env | {
          "SEMGREP_SETTINGS_FILE": settings_file.path,
          "SEMGREP_LOG_FILE": log_file.path,
          "RULES_LINT__SEMGREP__STDOUT_FILE": stdout.path,
        },
    )

# buildifier: disable=function-docstring
def _semgrep_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []

    outputs, info = output_files(_MNEMONIC, target, ctx)
    files_to_lint = filter_srcs(ctx.rule)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    human_options = ["--force-color"] if ctx.attr._options[LintOptionsInfo].color else ["--text"]
    semgrep_action(ctx, ctx.executable, files_to_lint, ctx.files._config, outputs.human.out, outputs.human.exit_code, env = ctx.attr._env, options = human_options)

    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    semgrep_action(ctx, ctx.executable, files_to_lint, ctx.files._config, raw_machine_report, outputs.machine.exit_code, env = ctx.attr._env, options = ["--sarif"])

    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)
    return [info]

RULE_KINDS = [
  # https://semgrep.dev/docs/supported-languages
  "cc_binary",
  "cc_library",
  "cc_test",
  "csharp_binary",
  "csharp_library",
  "csharp_test",
  "go_binary",
  "go_library",
  "go_test",
  "java_binary",
  "java_library",
  "java_test",
  # Upstream supports JS but `lint_aspect.bzl` fails with:
  # ```
  #  return [s for s in rule.files.srcs if s.is_source and s.owner.workspace_name == ""]
  #  Error: No attribute 'srcs' in files. Make sure there is a label or label_list type attribute with this name
  # ```
  # "js_binary",
  # "js_library",
  # "js_test",
  "kt_jvm_binary",
  "kt_jvm_library",
  "kt_jvm_test",
  "py_binary",
  "py_library",
  "py_test",
  # typescript
  "rb_binary",
  "rb_library",
  "rb_test",
  "rust_binary",
  "rust_library",
  "rust_test",
  "scala_binary",
  "scala_library",
  "scala_test",
  "swift_binary",
  "swift_library",
  "swift_test",
]

def lint_semgrep_aspect(binary, config = [], extra_options = [], env = {}, rule_kinds = RULE_KINDS):
    """A factory function to create a linter aspect.

    Args:
        binary: a semgrep executable. Can be obtained from pypi like so:

            load("@rules_python//python/entry_points:py_console_script_binary.bzl", "py_console_script_binary")

            py_console_script_binary(
                name = "semgrep",
                script = "pysemgrep",
                pkg = "@pip//semgrep:pkg",
            )

        config: label of the directory with semgrep rules (defaults to `auto`).
        extra_options: extra options passed to semgrep (["--oss-only"] for example).
        env: environment variables passed to the tool.
        rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect
    """
    return aspect(
        implementation = _semgrep_aspect_impl,
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_semgrep": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_semgrep_wrapper": attr.label(
                default = Label("@aspect_rules_lint//lint:semgrep_wrapper"),
                executable = True,
                cfg = "exec",
            ),
            "_config": attr.label_list(
                default = config,
                allow_files = True,
            ),
            "_extra_options": attr.string_list(
                default = extra_options,
            ),
            "_env": attr.string_dict(
                default = env,
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
        toolchains = [OPTIONAL_SARIF_PARSER_TOOLCHAIN],
    )
