"""API for calling declaring a buf lint aspect.

Typical usage:

```
load("@aspect_rules_lint//lint:buf.bzl", "lint_buf_aspect")

buf = lint_buf_aspect(
    config = Label("//path/to:buf.yaml"),
)
```

**Important:** the aspect lints the descriptor sets of `proto_library` targets, which only carry source locations with the bazel flag `--experimental_proto_descriptor_sets_include_source_info`.
Without it, every finding is reported at line 1, and buf's [`allow_comment_ignores` functionality](https://buf.build/docs/configuration/v1/buf-yaml#allow_comment_ignores) does not work.

For a [v2 `buf.yaml`](https://buf.build/docs/configuration/v2/buf-yaml) listing `modules`, set `infer_module = True` so each target is linted as part of the module rooted at its import root:

```
buf = lint_buf_aspect(
    config = Label("//:buf.yaml"),
    infer_module = True,
)
```
"""

load("@rules_proto//proto:defs.bzl", "ProtoInfo")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "output_files", "parse_to_sarif_action", "should_visit")

_MNEMONIC = "AspectRulesLintBuf"

def _short_path(file, _):
    return file.path

def _import_root(ctx):
    """Workspace-relative directory the visited proto_library's import paths are relative to."""
    attr = ctx.rule.attr
    prefix = getattr(attr, "strip_import_prefix", "/") or "/"
    if prefix.startswith("/"):
        return prefix.strip("/")
    return "/".join([p for p in [ctx.label.package, prefix.strip("/")] if p])

def _module(import_root, config):
    """Path of the buf.yaml module rooted at `import_root`, relative to the config's directory."""
    config_dir = config.short_path.rpartition("/")[0]
    if import_root == config_dir:
        return "."
    if not config_dir:
        return import_root
    if import_root.startswith(config_dir + "/"):
        return import_root[len(config_dir) + 1:]
    return ""

def buf_lint_action(ctx, buf, protoc, target, stderr, exit_code = None, args = [], module = ""):
    """Runs the buf lint tool as a Bazel action.

    Args:
        ctx: Rule OR Aspect context
        buf: the buf-lint executable
        protoc: the protoc executable
        target: the proto_library target to run on
        stderr: output file containing the stderr of protoc
        exit_code: output file to write the exit code.
            If None, then fail the build when protoc exits non-zero.
        args: additional command-line arguments passed to protoc
        module: path of the buf.yaml module the target belongs to, relative to the config.
            Required by v2 configs listing `modules`.
    """
    plugin_opt = {
        "input_config": "" if ctx.file._config == None else ctx.file._config.short_path,
    }
    if module:
        plugin_opt["module"] = module
    config = json.encode(plugin_opt)

    deps = depset(
        [target[ProtoInfo].direct_descriptor_set],
        transitive = [target[ProtoInfo].transitive_descriptor_sets],
    )

    sources = []
    source_files = []

    for f in target[ProtoInfo].direct_sources:
        source_files.append(f)

        # source is the argument passed to protoc. This is the import path "foo/foo.proto"
        # We have to trim the prefix if strip_import_prefix attr is used in proto_library.
        sources.append(
            f.path[len(target[ProtoInfo].proto_source_root) + 1:] if f.path.startswith(target[ProtoInfo].proto_source_root) else f.path,
        )

    action_args = ctx.actions.args()
    action_args.add_joined(["--plugin", "protoc-gen-buf-plugin", buf], join_with = "=")
    action_args.add_joined(["--buf-plugin_opt", config], join_with = "=")
    action_args.add_joined("--descriptor_set_in", deps, join_with = ":", map_each = _short_path)
    action_args.add_joined(["--buf-plugin_out", "."], join_with = "=")
    action_args.add_all(args)
    action_args.add_all(sources)
    outputs = [stderr]

    if exit_code:
        command = "{protoc} $@ 2>{stderr}; echo $? > " + exit_code.path
        outputs.append(exit_code)
    else:
        # Create empty file on success, as Bazel expects one
        command = "{protoc} $@ && touch {stderr}"

    ctx.actions.run_shell(
        inputs = depset([
            ctx.file._config,
            protoc,
            buf,
        ], transitive = [deps]),
        outputs = outputs,
        command = command.format(
            protoc = protoc.path,
            stderr = stderr.path,
        ),
        arguments = [action_args],
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with Buf",
    )

def _buf_lint_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []

    buf = ctx.toolchains[ctx.attr._buf_toolchain].cli
    protoc = ctx.toolchains["@rules_proto//proto:toolchain_type"].proto.proto_compiler.executable
    outputs, info = output_files(_MNEMONIC, target, ctx)

    # buf reports paths relative to the import root, possibly behind an import_prefix.
    import_root = _import_root(ctx)
    import_prefix = getattr(ctx.rule.attr, "import_prefix", "").strip("/")
    module = _module(import_root, ctx.file._config) if ctx.attr._infer_module else ""

    # TODO(alex): there should be a reason to run the buf action again rather than just copy the files
    buf_lint_action(ctx, buf, protoc, target, outputs.human.out, outputs.human.exit_code, args = ctx.attr._args, module = module)
    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    buf_lint_action(ctx, buf, protoc, target, raw_machine_report, outputs.machine.exit_code, args = ctx.attr._args, module = module)
    parse_to_sarif_action(
        ctx,
        _MNEMONIC,
        raw_machine_report,
        outputs.machine.out,
        strip_path_prefix = import_prefix + "/" if import_prefix else "",
        add_path_prefix = import_root + "/" if import_root else "",
    )
    return [info]

def lint_buf_aspect(config, toolchain = "@rules_buf//tools/protoc-gen-buf-lint:toolchain_type", rule_kinds = ["proto_library"], args = [], infer_module = False):
    """A factory function to create a linter aspect.

    Args:
        config: label of the buf.yaml file
        toolchain: override the default toolchain of the protoc-gen-buf-lint tool
        rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect
        args: additional options to pass to the underlying protoc invocation
        infer_module: lint each target as part of the buf.yaml module rooted at its import root.
            Required for a v2 buf.yaml listing `modules`, leave unset otherwise.
    """
    return aspect(
        implementation = _buf_lint_aspect_impl,
        attr_aspects = ["deps"],
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_buf_toolchain": attr.string(
                default = toolchain,
            ),
            "_config": attr.label(
                default = config,
                allow_single_file = True,
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
            "_args": attr.string_list(
                default = args,
            ),
            "_infer_module": attr.bool(
                default = infer_module,
            ),
        },
        toolchains = [
            toolchain,
            OPTIONAL_SARIF_PARSER_TOOLCHAIN,
            "@rules_proto//proto:toolchain_type",
        ],
    )
