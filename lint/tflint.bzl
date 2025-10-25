"""Configures [TFLint](https://github.com/terraform-linters/tflint) to run as a Bazel aspect.

Typical usage:

```starlark
load("@aspect_rules_lint//lint:tflint.bzl", "lint_tflint_aspect")
load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")

tflint = lint_tflint_aspect()
tflint_test = lint_test(aspect = tflint)
```

Because the aspect relies on toolchains provided by [`rules_tf`](https://github.com/yanndegat/rules_tf),
make sure your `MODULE.bazel` (or WORKSPACE equivalent) registers them:

```starlark
bazel_dep(name = "rules_tf", version = "0.0.10")

tf = use_extension("@rules_tf//tf:extensions.bzl", "tf_repositories")
tf.download(
    version = "1.9.8",
    mirror = {"aws": "hashicorp/aws:5.90.0"},
)
use_repo(tf, "tf_toolchains")
register_toolchains("@tf_toolchains//:all")
```

By default the aspect runs with the opinionated config bundled with `rules_tf`. To supply your own
configuration or forward CLI flags, pass the optional parameters:

```starlark
tflint = lint_tflint_aspect(
    config = "//terraform:custom_tflint.hcl",
    extra_args = ["--ignore-module=github.com/example"],
)
```

Attach the aspect to any rules that provide `TfModuleInfo`; the helper above is also compatible
with `lint_test` so Terraform violations can fail CI.
"""

load("@rules_tf//tf/rules:providers.bzl", "TfModuleInfo")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "should_visit")

_MNEMONIC = "AspectRulesLintTflint"

_TERRAFORM_EXTENSIONS = (".tf", ".tf.json")

def _terraform_files(files):
    return [f for f in files if f.basename.endswith(_TERRAFORM_EXTENSIONS)]

def _tflint_action(
        ctx,
        module,
        tflint_runtime,
        tf_runtime,
        stdout,
        exit_code = None,
        extra_args = []):
    """Run tflint under Bazel."""
    inputs = module.transitive_srcs.to_list() + tflint_runtime.deps + tf_runtime.deps

    # The wrapper accepts an optional custom config file argument.
    config = ""
    if ctx.files._config:
        config = ctx.files._config[0].short_path
        inputs.append(ctx.files._config[0])

    args = ctx.actions.args()
    args.add(tf_runtime.tf.path)
    args.add(tflint_runtime.runner.path)
    args.add(tf_runtime.mirror.path)
    args.add(module.module_path)
    args.add(config)
    args.add_all(extra_args)

    outputs = [stdout]
    if exit_code:
        outputs.append(exit_code)

    # We intentionally avoid `set -e` when recording the exit code so failures still emit output.
    command = """\
TF_BIN="$1"; RUNNER="$2"; MIRROR="$3"; MODULE="$4"; CONFIG="$5"; shift 5
TF_DIR="$(dirname "$TF_BIN")"
export PATH="$TF_DIR:$PATH"
"$TF_BIN" -chdir="$PWD/$MODULE" init -backend=false -input=false -plugin-dir="$PWD/$MIRROR" >/dev/null
"""

    if exit_code:
        command += """\
STATUS=0
"$RUNNER" "$MODULE" "$CONFIG" "$@" >"{stdout}" || STATUS=$?
echo "$STATUS" > "{exit_code}"
exit 0
""".format(stdout = stdout.path, exit_code = exit_code.path)
    else:
        command = "set -euo pipefail\n" + command
        command += "\"$RUNNER\" \"$MODULE\" \"$CONFIG\" \"$@\" >\"{stdout}\"\n".format(stdout = stdout.path)

    ctx.actions.run_shell(
        mnemonic = _MNEMONIC,
        inputs = inputs,
        tools = [tf_runtime.tf, tflint_runtime.runner],
        outputs = outputs,
        command = command,
        arguments = [args],
        progress_message = "Linting %{label} with TFLint",
    )

# buildifier: disable=function-docstring
def _tflint_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds, ctx.attr._filegroup_tags):
        return []

    if TfModuleInfo not in target:
        fail("Target {} does not provide TfModuleInfo required by lint_tflint_aspect.".format(target.label))

    module = target[TfModuleInfo]
    terraform_files = _terraform_files(filter_srcs(ctx.rule))
    outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(terraform_files) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    color_args = ["--color"] if ctx.attr._options[LintOptionsInfo].color else ["--no-color"]
    common_args = color_args + ["--call-module-type=none"] + ctx.attr._extra_args

    tflint_runtime = ctx.toolchains["@rules_tf//:tflint_toolchain_type"].runtime
    tf_runtime = ctx.toolchains["@rules_tf//:tf_toolchain_type"].runtime

    # Human-readable output
    _tflint_action(
        ctx = ctx,
        module = module,
        tflint_runtime = tflint_runtime,
        tf_runtime = tf_runtime,
        stdout = outputs.human.out,
        exit_code = outputs.human.exit_code,
        extra_args = common_args,
    )

    # Machine readable JSON output that we convert to SARIF.
    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    _tflint_action(
        ctx = ctx,
        module = module,
        tflint_runtime = tflint_runtime,
        tf_runtime = tf_runtime,
        stdout = raw_machine_report,
        exit_code = outputs.machine.exit_code,
        extra_args = common_args + ["--format", "sarif"],
    )
    ctx.actions.symlink(
        output = outputs.machine.out,
        target_file = raw_machine_report,
    )
    return [info]

def lint_tflint_aspect(
        config = None,
        extra_args = [],
        rule_kinds = ["tf_module"],
        filegroup_tags = ["lint-with-tflint"]):
    """Create an aspect that runs TFLint on Terraform modules defined by rules_tf."""
    return aspect(
        implementation = _tflint_aspect_impl,
        attr_aspects = ["deps"],
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_config": attr.label_list(
                allow_files = True,
                default = [config] if config else [],
            ),
            "_extra_args": attr.string_list(default = extra_args),
            "_rule_kinds": attr.string_list(default = rule_kinds),
            "_filegroup_tags": attr.string_list(default = filegroup_tags),
        },
        toolchains = [
            "@rules_tf//:tf_toolchain_type",
            "@rules_tf//:tflint_toolchain_type",
            OPTIONAL_SARIF_PARSER_TOOLCHAIN,
        ],
    )
