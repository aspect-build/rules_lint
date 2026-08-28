"""Configures [rumdl](https://github.com/rvben/rumdl) to lint Markdown files.

Markdown sources must belong to a `markdown_library` rule or to a `filegroup`
tagged with `markdown` or `lint-with-rumdl`.

Relative links can only resolve to files available in the Bazel sandbox. Pass
linked files that are not already sources through the `data` attribute.

Typical usage:

```starlark
load("@aspect_rules_lint//lint:rumdl.bzl", "lint_rumdl_aspect")

rumdl = lint_rumdl_aspect(
    binary = Label("@aspect_rules_lint//lint:rumdl_bin"),
    config = Label("//:.rumdl.toml"),
    data = [Label("//docs:link_targets")],
)
```
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "noop_lint_action", "output_files", "patch_and_output_files", "should_visit")
load("//lint/private:patcher_action.bzl", "patcher_attrs", "run_patcher")

_MNEMONIC = "AspectRulesLintRumdl"

_MARKDOWN_EXTENSIONS = (".md", ".mdx", ".qmd", ".Rmd")

def rumdl_action(ctx, executable, src, stdout, exit_code = None, config = None, data = [], output_format = None, args = [], patch = None):
    """Run rumdl as an action under Bazel.

    Args:
        ctx: Bazel rule or aspect evaluation context.
        executable: rumdl executable.
        src: Markdown file to lint.
        stdout: output file for rumdl diagnostics.
        exit_code: optional output file for the rumdl exit code. If absent, a
            non-zero exit fails the action.
        config: optional rumdl configuration file. When absent, rumdl runs with
            built-in defaults and does not discover configuration files.
        data: additional files available for local link and fragment resolution.
        output_format: optional value for rumdl's `--output-format` flag.
        args: additional lint-selection command-line arguments passed to rumdl.
            Do not pass output, color, cache, or configuration flags, which are
            managed by the aspect.
        patch: optional output file for fixes. When present, rumdl edits sandbox
            copies and the standard rules_lint patcher records the changes.
    """
    inputs = [src] + data
    if config:
        inputs.append(config)

    action_args = ctx.actions.args()
    if output_format:
        action_args.add_all(["--output-format", output_format])
    action_args.add_all(args)

    if patch:
        action_args.add("--fix")
        action_args.add(src.path)
        run_patcher(
            ctx,
            ctx.executable,
            inputs = inputs,
            args = action_args,
            files_to_diff = [src.path],
            files_to_copy = [file.path for file in _markdown_files(data)],
            patch_out = patch,
            tools = [executable],
            stdout = stdout,
            exit_code = exit_code,
            mnemonic = _MNEMONIC,
            progress_message = "Fixing %{label} with rumdl",
            patch_cfg_suffix = "rumdl.patch_cfg",
            patch_cfg_name = "{}_rules_lint/{}".format(ctx.label.name, src.short_path),
        )
        return

    markdown_data = _markdown_files(data)
    linked_data = [file for file in data if file not in markdown_data]
    context_args = ctx.actions.args()
    for file in markdown_data:
        context_args.add(file.path)
        context_args.add(file.short_path)
    linked_args = ctx.actions.args()
    for file in linked_data:
        linked_args.add(file.path)
        linked_args.add(file.short_path)

    outputs = [stdout]
    redirect = '>"{stdout}"' if output_format else '>"{stdout}" 2>&1'
    command = """root="$PWD"
workspace="${{TMPDIR:-/tmp}}/{workspace}"
rm -rf "$workspace"
trap 'rm -rf "$workspace"' EXIT
mkdir -p "$workspace/{src_dir}"
markdown_count="$1"; shift
while [ "$markdown_count" -gt 0 ]; do
    input="$1"; logical_path="$2"; shift 2
    mkdir -p "$workspace/$(dirname "$logical_path")"
    cp -L "$root/$input" "$workspace/$logical_path"
    markdown_count=$((markdown_count - 1))
done
linked_count="$1"; shift
while [ "$linked_count" -gt 0 ]; do
    input="$1"; logical_path="$2"; shift 2
    mkdir -p "$workspace/$(dirname "$logical_path")"
    ln -s "$root/$input" "$workspace/$logical_path"
    linked_count=$((linked_count - 1))
done
cd "$workspace"
""".format(
        src_dir = src.dirname,
        workspace = stdout.path.replace("/", "_"),
    )
    config_arg = '--config "$root/{config}"'.format(config = config.path) if config else "--no-config"
    if exit_code:
        command += '"$root/{rumdl}" check {config} "$@" --stdin --stdin-filename "{logical_src}" < "$root/{src}" {redirect}; echo $? > "$root/{exit_code}"'.format(
            rumdl = executable.path,
            config = config_arg,
            logical_src = src.short_path,
            src = src.path,
            redirect = redirect.format(stdout = "$root/" + stdout.path),
            exit_code = exit_code.path,
        )
        outputs.append(exit_code)
    else:
        command += '"$root/{rumdl}" check {config} "$@" --stdin --stdin-filename "{logical_src}" < "$root/{src}" {redirect}'.format(
            rumdl = executable.path,
            config = config_arg,
            logical_src = src.short_path,
            src = src.path,
            redirect = redirect.format(stdout = "$root/" + stdout.path),
        )

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        arguments = [str(len(markdown_data)), context_args, str(len(linked_data)), linked_args, action_args],
        tools = [executable],
        command = command,
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with rumdl",
    )

def _markdown_files(files):
    return [file for file in files if file.basename.endswith(_MARKDOWN_EXTENSIONS)]

# buildifier: disable=function-docstring
def _rumdl_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds, ctx.attr._filegroup_tags):
        return []

    files_to_lint = _markdown_files(filter_srcs(ctx.rule))
    target_data = ctx.rule.files.data if hasattr(ctx.rule.attr, "data") else []
    data = depset(ctx.files._data + target_data).to_list()
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx, files_to_lint = files_to_lint)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx, files_to_lint = files_to_lint)
    if len(files_to_lint) == 0:
        noop_outputs, info = output_files(_MNEMONIC, target, ctx)
        noop_lint_action(ctx, noop_outputs)
        return [info]

    common_args = ctx.attr._args + [
        "--color",
        "always" if ctx.attr._options[LintOptionsInfo].color else "never",
        "--deny-config-warnings",
        "--no-cache",
        "--quiet",
    ]
    if ctx.attr._options[LintOptionsInfo].debug:
        common_args.append("--verbose")
    for src, output in zip(files_to_lint, outputs):
        rumdl_action(
            ctx,
            ctx.executable._rumdl,
            src,
            output.human.out,
            output.human.exit_code,
            config = ctx.file._config_file,
            data = data,
            args = common_args,
            patch = getattr(output, "patch", None),
        )
        rumdl_action(
            ctx,
            ctx.executable._rumdl,
            src,
            output.machine.out,
            output.machine.exit_code,
            config = ctx.file._config_file,
            data = data,
            output_format = "sarif",
            args = ctx.attr._args + ["--color", "never", "--deny-config-warnings", "--no-cache"],
        )
    return [info]

def lint_rumdl_aspect(
        binary,
        config = None,
        data = [],
        rule_kinds = ["markdown_library"],
        filegroup_tags = ["markdown", "lint-with-rumdl"],
        args = []):
    """Create a rumdl lint aspect.

    Args:
        binary: a rumdl executable, such as `@aspect_rules_lint//lint:rumdl_bin`.
        config: optional rumdl configuration file. If omitted, only built-in
            defaults and command-line arguments are used.
        data: additional files to make available for local link and fragment
            resolution.
        rule_kinds: rule kinds visited by the aspect.
        filegroup_tags: tags that opt `filegroup` targets into rumdl linting.
        args: additional lint-selection command-line arguments passed to rumdl.
            Output, color, cache, and configuration flags are managed by the
            aspect and should not be included.

    Returns:
        An aspect definition for rumdl.
    """
    return aspect(
        implementation = _rumdl_aspect_impl,
        attrs = patcher_attrs | {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_rumdl": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(
                default = config,
                allow_single_file = True,
            ),
            "_data": attr.label_list(
                default = data,
                allow_files = True,
                doc = "Additional files available for local link resolution",
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
            "_filegroup_tags": attr.string_list(
                default = filegroup_tags,
            ),
            "_args": attr.string_list(
                default = args,
            ),
        },
    )
