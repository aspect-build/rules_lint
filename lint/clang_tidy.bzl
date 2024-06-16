"""API for calling declaring a clang-tidy lint aspect.

Typical usage:

First, install clang-tidy with llvm_toolchain or as a native binary (llvm_toolchain
does not support Windows as of 06/2024, but providing a native clang-tidy.exe works)

Next, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

e.g. using llvm_toolchain:
```starlark
native_binary(
    name = "clang_tidy",
    src = "@llvm_toolchain_llvm//:bin/clang-tidy"
    out = "clang_tidy",
)
```

e.g as native binary:
```starlark
native_binary(
    name = "clang_tidy",
    src = "clang-tidy.exe"
    out = "clang_tidy",
)
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

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "dummy_successful_lint_action", "report_files", "patch_and_report_files")

_MNEMONIC = "AspectRulesLintClangTidy"

def _gather_inputs(ctx, compilation_context, srcs):
    inputs = srcs + [ctx.file._config_file] + compilation_context.headers.to_list()
    return inputs

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

def _supported_flag(flag):
    # Some flags might be used by GCC, but not understood by Clang.
    # Remove them here, to allow users to run clang-tidy, without having
    # a clang toolchain configured (that would produce a good command line with --compiler clang)
    unsupported_flags = [
        "-fno-canonical-system-headers",
        "-fstack-usage",
        "/nologo",
        "/COMPILER_MSVC",
        "/showIncludes",
    ]
    if (flag in unsupported_flags or flag.startswith("/wd") or flag.startswith("-W")):
        return False
    return True

def _update_flag(flag):
    # update from MSVC C++ standard to clang C++ standard
    if (flag.startswith("/std:")):
        flag = "-std="+flag.removeprefix("/std:")
    return flag

def _safe_flags(flags):
    # Some flags might be used by GCC, but not understood by Clang.
    # Remove them here, to allow users to run clang-tidy, without having
    # a clang toolchain configured (that would produce a good command line with --compiler clang)
    return [_update_flag(flag) for flag in flags if (_supported_flag(flag))]

def _prefixed(list, prefix):
    array = []
    for arg in list:
        array.append(prefix)
        array.append(arg)
    return array

def _angle_includes_option(ctx):
    if (ctx.attr._angle_includes_are_system):
        return "-isystem"
    return "-I"
    
def _is_cxx(file):
    if file.extension == "c":
        return False
    return True

def _is_source(file):
    permitted_source_types = [
        "c", "cc", "cpp", "cxx", "c++", "C",
    ]
    return (file.is_source and file.extension in permitted_source_types)

# modification of filter_srcs in lint_aspect.bzl that filters out header files
def _filter_srcs(rule):
    if "lint-genfiles" in rule.attr.tags:
        return rule.files.srcs
    else:
        return [s for s in rule.files.srcs if _is_source(s)]

def _get_args(ctx, compilation_context, srcs):
    args = [src.short_path for src in srcs]
    args.append("--config-file="+ctx.file._config_file.short_path)
    if (ctx.attr._lint_matching_header):
        args.append("--wrapper_add_matching_header")
    elif (ctx.attr._header_filter):
        regex = ctx.attr._header_filter
        args.append("-header-filter="+regex)

    args.append("--")

    # add args specified by the toolchain, on the command line and rule copts
    rule_flags = ctx.rule.attr.copts if hasattr(ctx.rule.attr, "copts") else []
    sources_are_cxx = _is_cxx(srcs[0])
    if (sources_are_cxx):
        args.extend(_safe_flags(_toolchain_flags(ctx, ACTION_NAMES.cpp_compile) + rule_flags) + ["-xc++"])
    else:
        args.extend(_safe_flags(_toolchain_flags(ctx, ACTION_NAMES.c_compile) + rule_flags) + ["-xc"])

    # add defines
    for define in compilation_context.defines.to_list():
        args.append("-D" + define)
    for define in compilation_context.local_defines.to_list():
        args.append("-D" + define)

    # add includes
    args.extend(_prefixed(compilation_context.framework_includes.to_list(), "-F"))
    args.extend(_prefixed(compilation_context.includes.to_list(), "-I"))
    args.extend(_prefixed(compilation_context.quote_includes.to_list(), "-iquote"))
    args.extend(_prefixed(compilation_context.system_includes.to_list(), angle_includes_option(ctx)))
    args.extend(_prefixed(compilation_context.external_includes.to_list(), "-isystem"))

    return args

def clang_tidy_action(ctx, compilation_context, executable, srcs, stdout, exit_code):
    """Create a Bazel Action that spawns a clang-tidy process.

    Adapter for wrapping Bazel around
    https://clang.llvm.org/extra/clang-tidy/

    Args:
        ctx: an action context OR aspect context
        compilation_context: from target
        executable: struct with a clang-tidy field
        srcs: file objects to lint
        report: output file containing the stdout or --output-file of clang-tidy
        exit_code: output file containing the exit code of clang-tidy.
            If None, then fail the build when clang-tidy exits non-zero.
    """

    outputs = [stdout]
    env = {}
    env["CLANG_TIDY__STDOUT_STDERR_OUTPUT_FILE"] = stdout.path
    #env["CLANG_TIDY__VERBOSE"] = "1"
    if exit_code:
        env["CLANG_TIDY__EXIT_CODE_OUTPUT_FILE"] = exit_code.path
        outputs.append(exit_code)

    ctx.actions.run_shell(
        inputs = _gather_inputs(ctx, compilation_context, srcs),
        outputs = outputs,
        tools = [executable._clang_tidy_wrapper, executable._clang_tidy],
        command = executable._clang_tidy_wrapper.path + " $@",
        arguments = [executable._clang_tidy.path] + _get_args(ctx, compilation_context, srcs),
        use_default_shell_env = True,
        env = env,
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with clang-tidy",
    )

def clang_tidy_fix(ctx, compilation_context, executable, srcs, patch, stdout, exit_code):
    """Create a Bazel Action that spawns clang-tidy with --fix.

    Args:
        ctx: an action context OR aspect context
        compilation_context: from target
        executable: struct with a clang_tidy field
        srcs: list of file objects to lint
        patch: output file containing the applied fixes that can be applied with the patch(1) command.
        stdout: output file containing the stdout or --output-file of clang-tidy
        exit_code: output file containing the exit code of clang-tidy
    """
    patch_cfg = ctx.actions.declare_file("_{}.patch_cfg".format(ctx.label.name))

    args = get_args(ctx, compilation_context, srcs)
    ctx.actions.write(
        output = patch_cfg,
        content = json.encode({
            "linter": executable._clang_tidy_wrapper.path,
            "args": [executable._clang_tidy.path, "--fix"] + _get_args(ctx, compilation_context, srcs),
            "env": {
                #"CLANG_TIDY__VERBOSE": "1",
            },
            "files_to_diff": [src.path for src in srcs],
            "output": patch.path,
        }),
    )

    ctx.actions.run(
        inputs = _gather_inputs(ctx, compilation_context, srcs) + [patch_cfg],
        outputs = [patch, stdout, exit_code],
        executable = executable._patcher,
        arguments = [patch_cfg.path],
        env = {
            "BAZEL_BINDIR": ".",
            "JS_BINARY__EXIT_CODE_OUTPUT_FILE": exit_code.path,
            "JS_BINARY__STDOUT_OUTPUT_FILE": stdout.path,
            "JS_BINARY__SILENT_ON_SUCCESS": "1",
        },
        tools = [executable._clang_tidy_wrapper, executable._clang_tidy],
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with clang-tidy",
    )

# buildifier: disable=function-docstring
def _clang_tidy_aspect_impl(target, ctx):
    if not CcInfo in target:
        return []

    # todo: keep this? #Ignore external targets
    #if target.label.workspace_root.startswith("external"):
    #    return []

    # Targets with specific tags will not be formatted
    # todo: does this align with rules_lint framework?
    ignore_tags = [
        "noclangtidy",
        "no-clang-tidy",
    ]

    for tag in ignore_tags:
        if tag in ctx.rule.attr.tags:
            return []

    files_to_lint = _filter_srcs(ctx.rule)
    compilation_context = target[CcInfo].compilation_context

    if ctx.attr._options[LintOptionsInfo].fix:
        patch, report, exit_code, info = patch_and_report_files(_MNEMONIC, target, ctx)
        if len(files_to_lint) == 0:
            dummy_successful_lint_action(ctx, report, exit_code, patch)
        else:
            clang_tidy_fix(ctx, compilation_context, ctx.executable, files_to_lint, patch, report, exit_code)
    else:
        report, exit_code, info = report_files(_MNEMONIC, target, ctx)
        if len(files_to_lint) == 0:
            dummy_successful_lint_action(ctx, report, exit_code)
        else:
            clang_tidy_action(ctx, compilation_context, ctx.executable, files_to_lint, report, exit_code)
    return [info]

def lint_clang_tidy_aspect(binary, config, **kwargs):
    """A factory function to create a linter aspect.

    Args:
        binary: the clang-tidy binary, typically a rule like

            ```starlark
            native_binary(
                name = "clang_tidy",
                src = "clang-tidy.exe"
                out = "clang_tidy",
            )
            ```
        config: label of the .clang-tidy file
        header_filter: optional, set to a posix regex to supply to clang-tidy with the -header-filter option
        lint_matching_header: optional, set to True to include the matching header file
            in the lint output results for each source. If supplied, overrides the header_filter option.
        angle_includes_are_system: controls how angle includes are passed to clang-tidy. By default, Bazel
            passes these as -isystem. Change this to False to pass these as -I, which allows clang-tidy to regard
            them as regular header files.
    """

    return aspect(
        implementation = _clang_tidy_aspect_impl,
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_lint_matching_header": attr.bool(
                default = kwargs.get("lint_matching_header", False),
            ),
            "_header_filter": attr.string(
                default = kwargs.get("header_filter", ""),
            ),
            "_angle_includes_are_system": attr.bool(
                default = kwargs.get("angle_includes_are_system", True)
            ),
            "_clang_tidy": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_clang_tidy_wrapper": attr.label(
                default = Label("@aspect_rules_lint//lint:clang_tidy_wrapper"),
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(
                default = config,
                allow_single_file = True,
            ),
            "_patcher": attr.label(
                default = "@aspect_rules_lint//lint/private:patcher",
                executable = True,
                cfg = "exec",
            ),
            "_cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")),
        },
        toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
        fragments = ["cpp"],
    )
