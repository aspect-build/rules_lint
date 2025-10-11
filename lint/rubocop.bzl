"""API for declaring a RuboCop lint aspect that visits rb_{binary|library|test} rules.

Typical usage:

Users must provide their own RuboCop executable, typically installed via Bundler.
Create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:rubocop.bzl", "lint_rubocop_aspect")

rubocop = lint_rubocop_aspect(
    binary = "//tools/lint:rubocop",
    configs = ["//:rubocop.yml"],
)
```

## Installing RuboCop

The recommended approach is to use Bundler to manage RuboCop as a gem dependency:

1. Add RuboCop to your `Gemfile`:
```ruby
gem "rubocop", "~> 1.50"
```

2. Create a wrapper script or use rules_ruby's gem support to expose RuboCop as a Bazel target:
```starlark
# In tools/lint/BUILD.bazel
sh_binary(
    name = "rubocop",
    srcs = ["rubocop.sh"],
)
```

Where `rubocop.sh` might be:
```bash
#!/usr/bin/env bash
exec bundle exec rubocop "$@"
```

## Configuration

RuboCop will automatically discover `.rubocop.yml` files according to its standard configuration hierarchy.
See https://docs.rubocop.org/rubocop/configuration.html for details.

Note: all config files are passed to the action as inputs.
This means that a change to any config file invalidates the action cache entries for ALL
RuboCop actions.
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "patch_and_output_files", "should_visit")

_MNEMONIC = "AspectRulesLintRuboCop"

def rubocop_action(ctx, executable, srcs, config, stdout, exit_code = None, env = {}):
    """Run RuboCop as an action under Bazel.

    RuboCop will select the configuration file to use for each source file, as documented here:
    https://docs.rubocop.org/rubocop/configuration.html

    Note: all config files are passed to the action.
    This means that a change to any config file invalidates the action cache entries for ALL
    RuboCop actions.

    However this is needed because RuboCop's logic for selecting the appropriate config needs
    to traverse the directory hierarchy.

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the RuboCop program
        srcs: Ruby files to be linted
        config: labels of RuboCop config files (.rubocop.yml)
        stdout: output file of linter results to generate
        exit_code: output file to write the exit code.
            If None, then fail the build when RuboCop exits non-zero.
            See https://docs.rubocop.org/rubocop/usage/basic_usage.html#exit-codes
        env: environment variables for RuboCop
    """
    inputs = srcs + config
    outputs = [stdout]

    # Wire command-line options, see
    # `rubocop --help` to see available options
    args = ctx.actions.args()

    # Force format to simple for human-readable output
    args.add("--format", "simple")

    # Honor exclusions in .rubocop.yml even though we pass explicit list of files
    args.add("--force-exclusion")
    args.add_all(srcs)

    if exit_code:
        command = "{rubocop} $@ >{stdout}; echo $? >" + exit_code.path
        outputs.append(exit_code)
    else:
        # Create empty file on success, as Bazel expects one
        command = "{rubocop} $@ && touch {stdout}"

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        command = command.format(rubocop = executable.path, stdout = stdout.path),
        arguments = [args],
        mnemonic = _MNEMONIC,
        env = env,
        progress_message = "Linting %{label} with RuboCop",
        tools = [executable],
    )

def rubocop_fix(ctx, executable, srcs, config, patch, stdout, exit_code, env = {}):
    """Create a Bazel Action that spawns RuboCop with --autocorrect-all.

    Args:
        ctx: an action context OR aspect context
        executable: struct with _rubocop and _patcher field
        srcs: list of file objects to lint
        config: labels of RuboCop config files (.rubocop.yml)
        patch: output file containing the applied fixes that can be applied with the patch(1) command.
        stdout: output file of linter results to generate
        exit_code: output file to write the exit code
        env: environment variables for RuboCop
    """
    patch_cfg = ctx.actions.declare_file("_{}.patch_cfg".format(ctx.label.name))

    ctx.actions.write(
        output = patch_cfg,
        content = json.encode({
            "linter": executable._rubocop.path,
            "args": ["--autocorrect-all", "--force-exclusion"] + [s.path for s in srcs],
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
        tools = [executable._rubocop],
        mnemonic = _MNEMONIC,
        progress_message = "Fixing %{label} with RuboCop",
    )

# buildifier: disable=function-docstring
def _rubocop_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds, ctx.attr._filegroup_tags):
        return []

    files_to_lint = filter_srcs(ctx.rule)
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    color_env = {"RUBOCOP_FORCE_COLOR": "true"} if ctx.attr._options[LintOptionsInfo].color else {}

    # RuboCop can produce a patch at the same time as reporting the unpatched violations
    if hasattr(outputs, "patch"):
        rubocop_fix(ctx, ctx.executable, files_to_lint, ctx.files._config_files, outputs.patch, outputs.human.out, outputs.human.exit_code, env = color_env)
    else:
        rubocop_action(ctx, ctx.executable._rubocop, files_to_lint, ctx.files._config_files, outputs.human.out, outputs.human.exit_code, env = color_env)

    # Generate machine-readable report in JSON format for SARIF conversion
    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))

    # Create separate action for JSON output
    json_args = ctx.actions.args()
    json_args.add("--format", "json")
    json_args.add("--force-exclusion")
    json_args.add_all(files_to_lint)

    outputs_list = [raw_machine_report]
    if outputs.machine.exit_code:
        command = "{rubocop} $@ >{output}; echo $? >" + outputs.machine.exit_code.path
        outputs_list.append(outputs.machine.exit_code)
    else:
        command = "{rubocop} $@ >{output} || true"

    ctx.actions.run_shell(
        inputs = files_to_lint + ctx.files._config_files,
        outputs = outputs_list,
        command = command.format(
            rubocop = ctx.executable._rubocop.path,
            output = raw_machine_report.path,
        ),
        arguments = [json_args],
        mnemonic = _MNEMONIC,
        tools = [ctx.executable._rubocop],
    )

    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)

    return [info]

def lint_rubocop_aspect(binary, configs, rule_kinds = ["rb_binary", "rb_library", "rb_test"], filegroup_tags = ["ruby", "lint-with-rubocop"]):
    """A factory function to create a linter aspect.

    Args:
        binary: a RuboCop executable
        configs: RuboCop config file(s) (`.rubocop.yml`)
        rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect
        filegroup_tags: filegroups tagged with these tags will be visited by the aspect in addition to Ruby rule kinds
    """

    # syntax-sugar: allow a single config file in addition to a list
    if type(configs) == "string":
        configs = [configs]

    return aspect(
        implementation = _rubocop_aspect_impl,
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_rubocop": attr.label(
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
            "_filegroup_tags": attr.string_list(
                default = filegroup_tags,
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
        toolchains = [OPTIONAL_SARIF_PARSER_TOOLCHAIN],
    )
