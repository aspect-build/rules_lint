"""API for calling declaring a buf lint aspect.

Typical usage:

```
load("@aspect_rules_lint//lint:buf.bzl", "buf_lint_aspect")

buf = buf_lint_aspect(
    config = "@@//path/to:buf.yaml",
)
```
"""

load("@rules_proto//proto:defs.bzl", "ProtoInfo")

def _short_path(file, dir_exp):
    return file.path

def _buf_action(ctx, toolchain, target, report):
    config = json.encode({
        "input_config": "" if ctx.file._config == None else ctx.file._config.short_path,
    })

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

    args = ctx.actions.args()
    args.add_joined(["--plugin", "protoc-gen-buf-plugin", ctx.toolchains["@rules_buf//tools/protoc-gen-buf-lint:toolchain_type"].cli], join_with = "=")
    args.add_joined(["--buf-plugin_opt", config], join_with = "=")
    args.add_joined("--descriptor_set_in", deps, join_with = ":", map_each = _short_path)
    args.add_joined(["--buf-plugin_out", "."], join_with = "=")
    args.add_all(sources)

    ctx.actions.run_shell(
        inputs = depset([
            ctx.file._config,
            ctx.executable._protoc,
            ctx.toolchains["@rules_buf//tools/protoc-gen-buf-lint:toolchain_type"].cli,
        ], transitive = [deps]),
        outputs = [report],
        command = """\
            {protoc} $@ 2>{report} || true
        """.format(protoc = ctx.executable._protoc.path, report = report.path),
        arguments = [args],
    )

def _buf_lint_aspect_impl(target, ctx):
    if ctx.rule.kind in ["proto_library"]:
        report = ctx.actions.declare_file(target.label.name + ".buf-report.txt")
        _buf_action(ctx, ctx.attr._buf_toolchain, target, report)
        results = depset([report])
    else:
        results = depset()

    return [
        OutputGroupInfo(report = results),
    ]

def buf_lint_aspect(config, toolchain = "@rules_buf//tools/protoc-gen-buf-lint:toolchain_type"):
    """A factory function to create a linter aspect.

    Args:
        config: label of the the buf.yaml file
        toolchain: override the default toolchain of the protoc-gen-buf-lint tool
    """
    return aspect(
        implementation = _buf_lint_aspect_impl,
        attr_aspects = ["deps"],
        attrs = {
            "_buf_toolchain": attr.label(
                default = toolchain,
            ),
            "_config": attr.label(
                default = config,
                allow_single_file = True,
            ),
            "_protoc": attr.label(
                default = "@com_google_protobuf//:protoc",
                executable = True,
                cfg = "exec",
            ),
        },
        toolchains = [toolchain],
    )
