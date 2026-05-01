"""Configures [tflint](https://github.com/terraform-linters/tflint) to run as a Bazel aspect.

tflint is a pluggable Terraform linter that checks for possible errors, enforces best practices,
and applies naming conventions.

Typical usage:

Use the built-in tflint binary at `@aspect_rules_lint//lint:tflint_bin`, or provide your own
executable target (e.g. via [rules_multitool](https://github.com/theoremlp/rules_multitool)).

Then declare any tflint plugins you need using the `tflint_plugin` repository rule. In your `MODULE.bazel`:

```starlark
tflint_plugins = use_extension("@aspect_rules_lint//lint:tflint_plugins.bzl", "tflint_ext")
tflint_plugins.plugin(
    name = "tflint_plugin_google",
    ruleset_name = "google",
    sha256s = {
        "linux_amd64": "...",
        "darwin_arm64": "...",
    },
    url_template = "https://github.com/terraform-linters/tflint-ruleset-google/releases/download/v0.39.0/tflint-ruleset-google_{platform}.zip",
)
use_repo(tflint_plugins, "tflint_plugin_google")
```

Then declare the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:tflint.bzl", "lint_tflint_aspect")

tflint = lint_tflint_aspect(
    binary = "@aspect_rules_lint//lint:tflint_bin",
    config = Label("//:.tflint.hcl"),
    plugins = [
        Label("@tflint_plugin_google//:plugin"),
    ],
)
```

tflint operates on directories rather than individual files, so the aspect stages all `.tf` sources
from a target into a scratch directory before running the linter.

### Rule kinds

By default the aspect visits `tf_module` and `tf_environment` rule kinds. Use the `rule_kinds`
parameter to match your Terraform Bazel rules, and/or tag a `filegroup` with `lint-with-tflint`
to opt it in for linting.
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "noop_lint_action", "output_files", "should_visit")

_MNEMONIC = "AspectRulesLintTFLint"

def tflint_action(ctx, executable, srcs, stdout, exit_code = None, config = None, plugins = [], policies = [], format = "compact", options = []):
    """Run tflint as an action under Bazel.

    Because tflint operates on a directory rather than individual files, this action stages all
    source files into a scratch directory and points tflint at it.

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: File representing the tflint program
        srcs: Terraform (.tf) files to lint
        stdout: output file for tflint stdout
        exit_code: optional output file for exit code. If absent, non-zero exits fail the build.
        config: optional .tflint.hcl configuration file
        plugins: list of pre-fetched tflint plugin Files to symlink into the plugin directory
        policies: list of OPA policy Files (.rego) to stage alongside the Terraform sources
        format: tflint output format (e.g. "compact", "json")
        options: additional command-line options
    """
    inputs = list(srcs) + list(policies) + list(plugins)

    staging_dir = "{}.{}.staging".format(ctx.label.name, _MNEMONIC)

    # Determine the common package prefix for the source files so we can
    # rewrite tflint's output paths back to workspace-relative locations.
    src_prefix = srcs[0].short_path.rsplit("/", 1)[0] + "/" if srcs and "/" in srcs[0].short_path else ""

    # Symlink .tf sources into the scratch directory (flat — tflint lints one
    # module directory at a time). Absolute paths ensure symlinks resolve after
    # --chdir into the staging directory.
    copy_cmds = ["ln -s $PWD/{src} {dir}/{basename}".format(
        src = src.path,
        dir = staging_dir,
        basename = src.basename,
    ) for src in srcs]

    # Symlink OPA policy files preserving workspace-relative paths so
    # policy_dir in .tflint.hcl resolves correctly.
    policy_cmds = ["mkdir -p {dir}/{dirname} && ln -s $PWD/{src} {dir}/{path}".format(
        dir = staging_dir,
        dirname = f.short_path.rsplit("/", 1)[0],
        src = f.path,
        path = f.short_path,
    ) for f in policies]

    # Symlink pre-fetched plugins so tflint discovers them without --init
    # or network access.
    plugin_cmds = ["ln -s $PWD/{src} {dir}/.tflint.d/plugins/{basename}".format(
        src = f.path,
        dir = staging_dir,
        basename = f.basename,
    ) for f in plugins]

    config_flag = ""
    if config:
        # --chdir changes the working directory, so resolve the config path
        # relative to the exec root via $PWD before chdir happens.
        config_flag = "--config=$PWD/{config}".format(config = config.path)
        inputs.append(config)

    extra_flags = " ".join(options) if options else ""

    outputs = [stdout]
    if exit_code:
        command = """\
mkdir -p {dir}/.tflint.d/plugins
{copy_cmds}
{policy_cmds}
{plugin_cmds}
export TFLINT_PLUGIN_DIR=$PWD/{dir}/.tflint.d/plugins
{tflint} --chdir={dir} --call-module-type=none {config_flag} --format={format} {extra_flags} >{stdout}_raw 2>&1; rc=$?
sed 's|{sed_bare}|{sed_prefixed}|g' {stdout}_raw > {stdout}
echo $rc > {exit_code}
""".format(
            dir = staging_dir,
            copy_cmds = "\n".join(copy_cmds),
            policy_cmds = "\n".join(policy_cmds),
            plugin_cmds = "\n".join(plugin_cmds),
            tflint = executable.path,
            config_flag = config_flag,
            format = format,
            extra_flags = extra_flags,
            sed_bare = staging_dir + "/",
            sed_prefixed = src_prefix,
            stdout = stdout.path,
            exit_code = exit_code.path,
        )
        outputs.append(exit_code)
    else:
        command = """\
mkdir -p {dir}/.tflint.d/plugins
{copy_cmds}
{policy_cmds}
{plugin_cmds}
export TFLINT_PLUGIN_DIR=$PWD/{dir}/.tflint.d/plugins
{tflint} --chdir={dir} --call-module-type=none {config_flag} --format={format} {extra_flags} >{stdout}_raw 2>&1; rc=$?
sed 's|{sed_bare}|{sed_prefixed}|g' {stdout}_raw > {stdout}
exit $rc
""".format(
            dir = staging_dir,
            copy_cmds = "\n".join(copy_cmds),
            policy_cmds = "\n".join(policy_cmds),
            plugin_cmds = "\n".join(plugin_cmds),
            tflint = executable.path,
            config_flag = config_flag,
            format = format,
            extra_flags = extra_flags,
            sed_bare = staging_dir + "/",
            sed_prefixed = src_prefix,
            stdout = stdout.path,
        )

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        tools = [executable],
        command = command,
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with tflint",
    )

_TF_EXTENSIONS = (".tf",)

def _tf_files(files):
    return [f for f in files if f.path.endswith(_TF_EXTENSIONS)]

# buildifier: disable=function-docstring
def _tflint_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds, ctx.attr._filegroup_tags):
        return []

    files_to_lint = _tf_files(filter_srcs(ctx.rule))
    outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    plugin_files = []
    for plugin_target in ctx.attr._plugins:
        plugin_files.extend(plugin_target.files.to_list())

    common_args = {
        "ctx": ctx,
        "executable": ctx.executable._tflint,
        "srcs": files_to_lint,
        "config": ctx.file._config_file,
        "plugins": plugin_files,
        "policies": ctx.files._policies,
        "options": ctx.attr._extra_args,
    }

    # Human-readable output (compact format).
    tflint_action(
        stdout = outputs.human.out,
        exit_code = outputs.human.exit_code,
        format = "compact",
        **common_args
    )

    # Machine-readable output in SARIF format.
    # tflint supports --format=sarif natively, so we write directly to the
    # final report file — no parse_to_sarif_action conversion needed.
    tflint_action(
        stdout = outputs.machine.out,
        exit_code = outputs.machine.exit_code,
        format = "sarif",
        **common_args
    )
    return [info]

def lint_tflint_aspect(
        binary,
        config = None,
        plugins = [],
        policies = [],
        rule_kinds = ["tf_module", "tf_environment"],
        filegroup_tags = ["lint-with-tflint"],
        extra_args = []):
    """A factory function to create a tflint linter aspect.

    Args:
        binary: a tflint executable, typically `@aspect_rules_lint//lint:tflint_bin`.
        config: optional label for a `.tflint.hcl` configuration file.
        plugins: list of labels for pre-fetched tflint plugin binaries
            (from `tflint_plugin` repository rules).
        policies: list of labels for OPA policy files (`.rego`) used by
            the tflint-ruleset-opa plugin.
        rule_kinds: rule kinds the aspect should visit.
            Defaults to `["tf_module", "tf_environment"]`.
        filegroup_tags: tags on filegroup targets that opt them in for linting.
            Defaults to `["lint-with-tflint"]`.
        extra_args: additional command-line arguments passed to tflint.

    Returns:
        An aspect definition that can be used with `--aspects` or in `lint_test`.
    """
    return aspect(
        implementation = _tflint_aspect_impl,
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_tflint": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(
                default = config,
                allow_single_file = True,
            ),
            "_plugins": attr.label_list(
                default = plugins,
            ),
            "_policies": attr.label_list(
                default = policies,
                allow_files = [".rego"],
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
            "_filegroup_tags": attr.string_list(
                default = filegroup_tags,
            ),
            "_extra_args": attr.string_list(
                default = extra_args,
            ),
        },
    )
