"""API for declaring a RuboCop lint aspect that visits rb_{binary|library|test}
rules.

Typical usage:

## Installing RuboCop

The recommended approach is to use Bundler with rules_ruby to manage RuboCop
as a gem dependency:

1. Add RuboCop to your `Gemfile`:
```ruby
gem "rubocop", "~> 1.50"
```

2. Run `bundle lock` to generate `Gemfile.lock`

3. Configure the bundle in your `MODULE.bazel`:
```starlark
ruby = use_extension("@rules_ruby//ruby:extensions.bzl", "ruby")
ruby.toolchain(
    name = "ruby",
    version = "3.3.0",
)
ruby.bundle_fetch(
    name = "bundle",
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
)
use_repo(ruby, "bundle", "ruby", "ruby_toolchains")
```

4. Create an alias to the gem-provided binary in
   `tools/lint/BUILD.bazel`:
```starlark
alias(
    name = "rubocop",
    actual = "@bundle//bin:rubocop",
)
```

5. Create the linter aspect, typically in `tools/lint/linters.bzl`:
```starlark
load("@aspect_rules_lint//lint:rubocop.bzl", "lint_rubocop_aspect")

rubocop = lint_rubocop_aspect(
    binary = "//tools/lint:rubocop",
    configs = ["//:rubocop.yml"],
)
```

This approach ensures:
- Hermetic builds with pinned gem versions
- Consistent RuboCop versions across all developers
- Integration with Bazel's dependency management

## Configuration

RuboCop will automatically discover `.rubocop.yml` files according to its
standard configuration hierarchy.
See https://docs.rubocop.org/rubocop/configuration.html for details.

Note: all config files are passed to the action as inputs.
This means that a change to any config file invalidates the action cache
entries for ALL RuboCop actions.
"""

load(
    "//lint/private:lint_aspect.bzl",
    "LintOptionsInfo",
    "OPTIONAL_SARIF_PARSER_TOOLCHAIN",
    "OUTFILE_FORMAT",
    "filter_srcs",
    "noop_lint_action",
    "output_files",
    "parse_to_sarif_action",
    "patch_and_output_files",
    "should_visit",
)
load("//lint/private:patcher_action.bzl", "patcher_attrs", "run_patcher")

_MNEMONIC = "AspectRulesLintRuboCop"

def _build_rubocop_command(rubocop_path, stdout_path, exit_code_path = None):
    """Build shell command for running RuboCop.

    Args:
        rubocop_path: path to the RuboCop executable
        stdout_path: path where stdout/stderr should be written
        exit_code_path: path where exit code should be written. If None,
            the command will fail on non-zero exit.

    Returns:
        Fully formatted shell command string
    """
    cmd_parts = [
        "{rubocop} $@ >{stdout} 2>&1".format(
            rubocop = rubocop_path,
            stdout = stdout_path,
        ),
    ]
    if exit_code_path:
        cmd_parts.append(
            "; echo $? >{exit_code}".format(exit_code = exit_code_path),
        )
    return "".join(cmd_parts)

def rubocop_action(
        ctx,
        executable,
        srcs,
        config,
        stdout,
        exit_code = None,
        color = False):
    """Run RuboCop as an action under Bazel.

    RuboCop will select the configuration file to use for each source file,
    as documented here:
    https://docs.rubocop.org/rubocop/configuration.html

    Note: all config files are passed to the action.
    This means that a change to any config file invalidates the action cache
    entries for ALL RuboCop actions.

    However this is needed because RuboCop's logic for selecting the
    appropriate config needs to traverse the directory hierarchy.

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: File object for the RuboCop executable
        srcs: list of File objects for Ruby source files to be linted
        config: list of File objects for RuboCop config files (.rubocop.yml)
        stdout: File object where linter output will be written
        exit_code: File object where exit code will be written, or None.
            If None, the build will fail when RuboCop exits non-zero.
            See https://docs.rubocop.org/rubocop/usage/basic_usage.html
        color: boolean, whether to enable color output
    """
    inputs = srcs + config
    outputs = [stdout]

    # Wire command-line options, see
    # `rubocop --help` to see available options
    args = ctx.actions.args()

    # Force format to simple for human-readable output
    args.add("--format", "simple")

    # Honor exclusions in .rubocop.yml even though we pass explicit list of
    # files
    args.add("--force-exclusion")

    # Set cache root to /tmp to avoid sandbox permission issues
    # RuboCop's server feature needs a writable cache directory
    # Note: We can't use --cache false with --cache-root, so we allow caching to /tmp
    # Note: We don't pass --no-server because it causes errors with JRuby
    args.add("--cache-root", "/tmp")

    # Enable color output if requested
    if color:
        args.add("--color")

    args.add_all(srcs)

    command = _build_rubocop_command(
        executable.path,
        stdout.path,
        exit_code.path if exit_code else None,
    )
    if exit_code:
        outputs.append(exit_code)

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        command = command,
        arguments = [args],
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with RuboCop",
        tools = [executable],
    )

# buildifier: disable=function-docstring
def _rubocop_aspect_impl(target, ctx):
    if not should_visit(
        ctx.rule,
        ctx.attr._rule_kinds,
        ctx.attr._filegroup_tags,
    ):
        return []

    files_to_lint = filter_srcs(ctx.rule)
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    # RuboCop can produce a patch at the same time as reporting the
    # unpatched violations
    if hasattr(outputs, "patch"):
        rubocop_fix_args = [
            "--autocorrect-all",
            "--force-exclusion",
            "--cache",
            "false",
        ]
        if ctx.attr._options[LintOptionsInfo].color:
            rubocop_fix_args.append("--color")
        rubocop_fix_args.extend([s.path for s in files_to_lint])
        run_patcher(
            ctx,
            ctx.executable,
            inputs = files_to_lint + ctx.files._config_files,
            args = rubocop_fix_args,
            files_to_diff = [s.path for s in files_to_lint],
            patch_out = outputs.patch,
            tools = [ctx.executable._rubocop],
            stdout = outputs.human.out,
            exit_code = outputs.human.exit_code,
            mnemonic = _MNEMONIC,
            progress_message = "Fixing %{label} with RuboCop",
        )
    else:
        rubocop_action(
            ctx,
            ctx.executable._rubocop,
            files_to_lint,
            ctx.files._config_files,
            outputs.human.out,
            outputs.human.exit_code,
            color = ctx.attr._options[LintOptionsInfo].color,
        )

    # Generate machine-readable report in JSON format for SARIF conversion
    raw_machine_report = ctx.actions.declare_file(
        OUTFILE_FORMAT.format(
            label = target.label.name,
            mnemonic = _MNEMONIC,
            suffix = "raw_machine_report",
        ),
    )

    # Create separate action for JSON output
    json_args = ctx.actions.args()

    # Use JSON format for machine-readable output (converted to SARIF)
    json_args.add("--format", "json")

    # Honor exclusions in .rubocop.yml even though we pass explicit list of
    # files
    json_args.add("--force-exclusion")

    # Disable caching as Bazel handles caching at the action level
    json_args.add("--cache", "false")
    json_args.add_all(files_to_lint)

    outputs_list = [raw_machine_report]
    command = _build_rubocop_command(
        ctx.executable._rubocop.path,
        raw_machine_report.path,
        outputs.machine.exit_code.path if outputs.machine.exit_code else None,
    )
    if outputs.machine.exit_code:
        outputs_list.append(outputs.machine.exit_code)

    ctx.actions.run_shell(
        inputs = files_to_lint + ctx.files._config_files,
        outputs = outputs_list,
        command = command,
        arguments = [json_args],
        mnemonic = _MNEMONIC,
        progress_message = """\
Generating machine-readable report for %{label} with RuboCop\
""",
        tools = [ctx.executable._rubocop],
    )

    parse_to_sarif_action(
        ctx,
        _MNEMONIC,
        raw_machine_report,
        outputs.machine.out,
    )

    return [info]

def lint_rubocop_aspect(
        binary,
        configs,
        rule_kinds = ["rb_binary", "rb_library", "rb_test"],
        filegroup_tags = ["ruby", "lint-with-rubocop"]):
    """A factory function to create a linter aspect.

    Args:
        binary: Label of the RuboCop executable.
            Example: "//tools/lint:rubocop" or "@bundle//bin:rubocop"
        configs: Label or list of Labels of RuboCop config file(s).
            Example: ["//:rubocop.yml"] or "//:rubocop.yml"
        rule_kinds: list of rule kinds to visit.
            See https://bazel.build/query/language#kind
        filegroup_tags: list of filegroup tags. Filegroups with these tags
            will be visited by the aspect in addition to Ruby rule kinds.
    """

    # syntax-sugar: allow a single config file in addition to a list
    if type(configs) == "string":
        configs = [configs]

    return aspect(
        implementation = _rubocop_aspect_impl,
        attrs = patcher_attrs | {
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
