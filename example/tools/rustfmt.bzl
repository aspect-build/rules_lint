def rustfmt_binary_impl(ctx):
    """Creates an executable target from the current rust toolchain."""
    toolchain = ctx.toolchains[str(Label("@rules_rust//rust/rustfmt:toolchain_type"))]

    out_file = ctx.actions.declare_file("{name}.rustfmt".format(name = ctx.attr.name))

    script = """#!/usr/bin/env bash
    {rustfmt} $@
    """.format(rustfmt = toolchain.rustfmt.path)

    ctx.actions.write(
        output = out_file,
        content = script,
        is_executable = True,
    )

    return [
        DefaultInfo(
            executable = out_file,
            runfiles = ctx.runfiles(transitive_files = toolchain.all_files),
        ),
    ]

rustfmt_binary = rule(
    implementation = rustfmt_binary_impl,
    executable = True,
    toolchains = [
        str(Label("@rules_rust//rust/rustfmt:toolchain_type")),
    ],
)
