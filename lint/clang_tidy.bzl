"""API for calling declaring a clang-tidy lint aspect.

Typical usage:

First, install clang-tidy with llvm_toolchain or as a native binary (llvm_toolchain
does not support Windows as of 06/2024, but providing a native clang-tidy.exe works)

Next, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
# todo
load("@npm//:eslint/package_json.bzl", eslint_bin = "bin")
eslint_bin.eslint_binary(name = "eslint")
```

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:clang_tidy.bzl", "clang_tidy_aspect")

clang_tidy = clang_tidy_aspect(
    binary = "@@//path/to:clang-tidy",
    configs = "@@//path/to:.clang-tidy",
)
```
"""

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "COPY_FILE_TO_BIN_TOOLCHAINS", "copy_files_to_bin_actions")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "dummy_successful_lint_action", "filter_srcs", "patch_file", "report_files")

_MNEMONIC = "AspectRulesLintClangTidy"

def _rule_sources(ctx):
    def check_valid_file_type(src):
        """
        Returns True if the file type matches one of the permitted srcs file types for C and C++ header/source files.
        """
        permitted_file_types = [
            ".c", ".cc", ".cpp", ".cxx", ".c++", ".C", ".h", ".hh", ".hpp", ".hxx", ".inc", ".inl", ".H",
        ]
        for file_type in permitted_file_types:
            if src.basename.endswith(file_type):
                return True
        return False

    srcs = []
    if hasattr(ctx.rule.attr, "srcs"):
        for src in ctx.rule.attr.srcs:
            srcs += [src for src in src.files.to_list() if src.is_source and check_valid_file_type(src)]
    if hasattr(ctx.rule.attr, "hdrs"):
        for hdr in ctx.rule.attr.hdrs:
            srcs += [hdr for hdr in hdr.files.to_list() if hdr.is_source and check_valid_file_type(hdr)]
    return srcs

def _toolchain_flags(ctx, action_name = ACTION_NAMES.cpp_compile):
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
    )
    compile_variables = cc_common.create_compile_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        user_compile_flags = ctx.fragments.cpp.cxxopts + ctx.fragments.cpp.copts,
    )
    flags = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = action_name,
        variables = compile_variables,
    )
    return flags

def _safe_flags(flags):
    # Some flags might be used by GCC, but not understood by Clang.
    # Remove them here, to allow users to run clang-tidy, without having
    # a clang toolchain configured (that would produce a good command line with --compiler clang)
    unsupported_flags = [
        "-fno-canonical-system-headers",
        "-fstack-usage",
    ]

    return [flag for flag in flags if flag not in unsupported_flags]

def clang_tidy_action(ctx, compilation_context, executable, src, report, exit_code = None):
    """Create a Bazel Action that spawns a clang-tidy process.

    Adapter for wrapping Bazel around
    https://clang.llvm.org/extra/clang-tidy/

    Args:
        ctx: an action context OR aspect context
        executable: struct with a clang-tidy field
        src: single file object to lint
        report: output file containing the stdout or --output-file of clang-tidy
        exit_code: output file containing the exit code of clang-tidy.
            If None, then fail the build when clang-tidy exits non-zero.
    """

    args = ctx.actions.args()

    # TODO: enable if debug config, similar to rules_ts
    # args.add("--debug")

    rule_flags = ctx.rule.attr.copts if hasattr(ctx.rule.attr, "copts") else []
    c_flags = _safe_flags(_toolchain_flags(ctx, ACTION_NAMES.c_compile) + rule_flags) + ["-xc"]
    cxx_flags = _safe_flags(_toolchain_flags(ctx, ACTION_NAMES.cpp_compile) + rule_flags) + ["-xc++"]

    # file to lint
    args.add(src)

    # we can specify a single config file
    args.add("--config-file="+ctx.attr._config_files[0])

    # start compiler args
    args.add("--")

    # add args specified by the toolchain, on the command line and rule copts
    # todo: switch between c and cxx flags
    args.add_all(cxx_flags)

    # add defines
    for define in compilation_context.defines.to_list():
        args.add("-D" + define)

    for define in compilation_context.local_defines.to_list():
        args.add("-D" + define)

    # add includes
    for i in compilation_context.framework_includes.to_list():
        args.add("-F" + i)

    for i in compilation_context.includes.to_list():
        args.add("-I" + i)

    args.add_all(compilation_context.quote_includes.to_list(), before_each = "-iquote")

    args.add_all(compilation_context.system_includes.to_list(), before_each = "-isystem")
    print(args)

    env = {"BAZEL_BINDIR": ctx.bin_dir.path}

    if not exit_code:
        ctx.actions.run_shell(
            inputs = [src] + ctx.attr._config_files,
            outputs = [report],
            tools = [executable._clang_tidy],
            arguments = [args, src.short_path],
            command = executable._clang_tidy.path + " $@ && touch " + report.path,
            env = env,
            mnemonic = _MNEMONIC,
            progress_message = "Linting %{label} with clang-tidy",
        )
    else:
        # Workaround: create an empty report file in case clang-tidy doesn't write one
        # Use `../../..` to return to the execroot?
        #args.add_joined(["--node_options", "--require", "../../../" + ctx.file._workaround_17660.path], join_with = "=")
        args.add_all(["--output-file", report.short_path])

        env["JS_BINARY__EXIT_CODE_OUTPUT_FILE"] = exit_code.path

        ctx.actions.run(
            inputs = [src] + ctx.attr._config_files,
            outputs = [report, exit_code],
            executable = executable._clang_tidy,
            arguments = [args, src.short_path],
            env = env,
            mnemonic = _MNEMONIC,
            progress_message = "Linting %{label} with clang-tidy",
        )

def clang_tidy_fix(ctx, compilation_context, executable, src, patch, stdout, exit_code):
    """Create a Bazel Action that spawns clang-tidy with --fix.

    Args:
        ctx: an action context OR aspect context
        executable: struct with a clang_tidy field
        srcs: list of file objects to lint
        patch: output file containing the applied fixes that can be applied with the patch(1) command.
        stdout: output file containing the stdout or --output-file of clang-tidy
        exit_code: output file containing the exit code of clang-tidy
    """
    patch_cfg = ctx.actions.declare_file("_{}.patch_cfg".format(ctx.label.name))

    ctx.actions.write(
        output = patch_cfg,
        content = json.encode({
            "linter": executable._clang_tidy.path,
            "args": ["--fix"] + [src.short_path],
            "env": {"BAZEL_BINDIR": ctx.bin_dir.path},
            "files_to_diff": [src.path],
            "output": patch.path,
        }),
    )

    ctx.actions.run(
        inputs = [src, patch_cfg],
        outputs = [patch, stdout, exit_code],
        executable = executable._patcher,
        arguments = [patch_cfg.path],
        env = {"BAZEL_BINDIR": "."},
        tools = [executable._clang_tidy],
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with clang-tidy",
    )

# buildifier: disable=function-docstring
def _clang_tidy_aspect_impl(target, ctx):
    print("in aspect")
    if ctx.rule.kind not in ["cc_library", "cc_binary", "cc_shared_library"]:
        return []

    files_to_lint = filter_srcs(ctx.rule)
    #files_to_lint = _rule_sources(ctx)
    print(files_to_lint)
    compilation_context = target[CcInfo].compilation_context
    reports = []
    patches = []
    # todo: once working, add support for dummy_successful_lint_action on zero files_to_lint
    for file_to_lint in files_to_lint:
        report, exit_code, _ = report_files(_MNEMONIC, target, ctx)
        reports.append(report)
        reports.append(exit_code)
        if ctx.attr._options[LintOptionsInfo].fix:
            patch, _ = patch_file(_MNEMONIC, target, ctx)
            patches.append(patch)
            clang_tidy_fix(ctx, compilation_context, ctx.executable, file_to_lint, patch, report, exit_code)
        else:
            clang_tidy_action(ctx, compilation_context, ctx.executable, file_to_lint, report, exit_code)
    return [OutputGroupInfo(
        rules_lint_report = depset(reports),
        rules_lint_patch = depset(patches),
    )]

def lint_clang_tidy_aspect(binary, configs):
    """A factory function to create a linter aspect.

    Args:
        binary: the clang-tidy binary, typically a rule like

            ```
            load("@npm//:eslint/package_json.bzl", eslint_bin = "bin")
            eslint_bin.eslint_binary(name = "eslint")
            ```
        configs: label(s) of the .clang-tidy file
    """

    # syntax-sugar: allow a single config file in addition to a list
    print("creating aspect")
    print(binary)
    print(configs)
    if type(configs) == "string":
        configs = [configs]
    return aspect(
        implementation = _clang_tidy_aspect_impl,
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_clang_tidy": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config_files": attr.label_list(
                default = configs,
                allow_files = True,
            ),
            "_patcher": attr.label(
                default = "@aspect_rules_lint//lint/private:patcher",
                executable = True,
                cfg = "exec",
            ),
            "_cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")),
        },
        toolchains = COPY_FILE_TO_BIN_TOOLCHAINS + ["@bazel_tools//tools/cpp:toolchain_type"],
        fragments = ["cpp"],
        required_providers = ["CcInfo"],
    )
