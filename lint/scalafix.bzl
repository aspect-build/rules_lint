"""API for declaring a Scalafix lint aspect that visits scala_library, scala_binary, and scala_test rules.

Scalafix is a linting and refactoring tool for Scala that supports both syntactic and semantic rules.
See https://scalacenter.github.io/scalafix/

Typical usage:

First, fetch scalafix using rules_jvm_external in your MODULE.bazel:

```starlark
maven = use_extension("@rules_jvm_external//:extensions.bzl", "maven")
maven.install(
    artifacts = [
        "ch.epfl.scala:scalafix-cli_2.13.18:0.14.5",
    ],
    lock_file = "@//:maven_install.json",
    repositories = [
        "https://maven.google.com",
        "https://repo1.maven.org/maven2",
    ],
)
use_repo(maven, "maven")
```

Next, declare a binary target for it, typically in `tools/lint/BUILD.bazel`:

```starlark
load("@rules_java//java:defs.bzl", "java_binary")

java_binary(
    name = "scalafix",
    main_class = "scalafix.cli.Cli",
    runtime_deps = ["@maven//:ch_epfl_scala_scalafix_cli_2_13_18"],
    visibility = ["//visibility:public"],
)
```

Finally, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:scalafix.bzl", "lint_scalafix_aspect")

scalafix = lint_scalafix_aspect(
    binary = Label("//tools/lint:scalafix"),
    config = Label("//:.scalafix.conf"),
)
```

## Semantic Mode

Scalafix supports two types of rules:
- **Syntactic rules**: Run on source code without compilation (default)
- **Semantic rules**: Require SemanticDB data from compilation

To enable semantic rules (e.g., OrganizeImports with removeUnused):

1. Enable SemanticDB in your scala_toolchain:
   ```starlark
   scala_toolchain(
       name = "my_toolchain",
       enable_semanticdb = True,
       semanticdb_bundle_in_jar = False,
       ...
   )
   ```

2. Create the aspect with semantic=True:
   ```starlark
   scalafix = lint_scalafix_aspect(
       binary = Label("//tools/lint:scalafix"),
       config = Label("//:.scalafix.conf"),
       semantic = True,
   )
   ```
"""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@rules_java//java/common/rules:java_runtime.bzl", "JavaRuntimeInfo")
load("@rules_java//java:defs.bzl", "JavaInfo")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "patch_and_output_files", "should_visit")
load("//lint/private:patcher_action.bzl", "patcher_attrs", "run_patcher")

_MNEMONIC = "AspectRulesLintScalafix"

def scalafix_action(ctx, executable, srcs, config, stdout, java_runtime, exit_code = None, options = [], patch = None, classpath = None, semanticdb_targetroots = None, sourceroot = None):
    """Run scalafix as a build action in Bazel.

    Adapter for wrapping Bazel around
    https://scalacenter.github.io/scalafix/docs/users/installation.html

    Args:
        ctx: an action context or aspect context
        executable: struct with scalafix field (the java_binary)
        srcs: A list of Scala source files to lint
        config: The .scalafix.conf configuration file
        stdout: output file for linter results
        java_runtime: The Java Runtime configured for this build, from the registered toolchain
        exit_code: output file to write the exit code.
            If None, then fail the build when scalafix exits non-zero.
        options: additional command-line arguments to scalafix
        patch: output file for patch (optional). If provided, uses run_patcher for fix mode.
        classpath: For semantic rules - transitive compile classpath (list of jars)
        semanticdb_targetroots: Directories containing .semanticdb files (list of paths)
        sourceroot: Root directory for relative path resolution
    """
    args = ctx.actions.args()
    args.add_all(options)

    inputs = list(srcs)
    outputs = [stdout]

    # Java runtime from toolchain for hermetic execution
    java_home = java_runtime[JavaRuntimeInfo].java_home
    java_runtime_files = java_runtime[JavaRuntimeInfo].files
    env = {
        "JAVA_HOME": java_home,
    }

    inputs.append(executable)

    # Add config file
    if config:
        inputs.append(config)
        args.add("--config", config.path)

    # Semantic mode arguments
    if classpath and semanticdb_targetroots:
        # Semantic mode: pass classpath and semanticdb info
        args.add("--classpath", ":".join([jar.path for jar in classpath]))
        args.add("--semanticdb-targetroots", ":".join(semanticdb_targetroots))
        if sourceroot:
            args.add("--sourceroot", sourceroot)
        inputs.extend(classpath)
    else:
        # Syntactic mode: no compilation data needed
        args.add("--syntactic")

    # Add source files
    args.add("--files")
    args.add_all(srcs)

    # Include Java runtime files required for scalafix
    inputs = depset(direct = inputs, transitive = [java_runtime_files])

    # Make hermetic java available to scalafix
    command = "export PATH=$PATH:$JAVA_HOME/bin\n"

    if patch != None:
        # Use run_patcher for fix mode
        args_list = ["--config", config.path] if config else []
        if classpath and semanticdb_targetroots:
            args_list.extend(["--classpath", ":".join([jar.path for jar in classpath])])
            args_list.extend(["--semanticdb-targetroots", ":".join(semanticdb_targetroots)])
            if sourceroot:
                args_list.extend(["--sourceroot", sourceroot])
        else:
            args_list.append("--syntactic")
        args_list.append("--files")
        args_list.extend([s.path for s in srcs])

        run_patcher(
            ctx,
            ctx.executable,
            inputs = inputs.to_list() if hasattr(inputs, "to_list") else inputs,
            args = args_list,
            files_to_diff = [s.path for s in srcs],
            patch_out = patch,
            tools = [executable],
            stdout = stdout,
            exit_code = exit_code,
            env = env,
            mnemonic = _MNEMONIC,
            progress_message = "Fixing %{label} with Scalafix",
        )
    else:
        # Lint mode with --check
        args.add("--check")

        if exit_code:
            # Don't fail scalafix and just report the violations
            command += "{scalafix} $@ >{stdout}; echo $? >" + exit_code.path
            outputs.append(exit_code)
        else:
            # Run scalafix with arguments passed
            command += "{scalafix} $@ && touch {stdout}"

        ctx.actions.run_shell(
            inputs = inputs,
            outputs = outputs,
            command = command.format(scalafix = executable.path, stdout = stdout.path),
            arguments = [args],
            mnemonic = _MNEMONIC,
            progress_message = "Linting %{label} with Scalafix",
            env = env,
        )

def _scalafix_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []

    files_to_lint = filter_srcs(ctx.rule)

    # Determine if we should use fix mode
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    color_options = []  # scalafix doesn't have a color option, output is plain text

    # Semantic mode: collect classpath and semanticdb files
    classpath = None
    semanticdb_targetroots = None
    sourceroot = None

    if ctx.attr._semantic and JavaInfo in target:
        # Access classpath from JavaInfo (like spotbugs)
        classpath = target[JavaInfo].transitive_compile_time_jars.to_list()

        # Access .semanticdb files from target outputs
        # rules_scala outputs these when enable_semanticdb = True
        semanticdb_files = [f for f in target.files.to_list() if f.path.endswith(".semanticdb")]

        if semanticdb_files:
            # Determine semanticdb root from file paths
            # SemanticDB files are typically in META-INF/semanticdb/ relative to output
            semanticdb_roots = []
            for f in semanticdb_files:
                # Find the parent directory containing META-INF/semanticdb
                path_parts = f.path.split("/")
                if "META-INF" in path_parts:
                    idx = path_parts.index("META-INF")
                    root = "/".join(path_parts[:idx])
                    if root and root not in semanticdb_roots:
                        semanticdb_roots.append(root)
            if semanticdb_roots:
                semanticdb_targetroots = semanticdb_roots
                sourceroot = "."  # Use workspace root

    # Human-readable output
    scalafix_action(
        ctx,
        ctx.executable._scalafix,
        files_to_lint,
        ctx.file._config,
        outputs.human.out,
        ctx.attr._java_runtime,
        outputs.human.exit_code,
        color_options,
        patch = getattr(outputs, "patch", None),
        classpath = classpath,
        semanticdb_targetroots = semanticdb_targetroots,
        sourceroot = sourceroot,
    )

    # Machine-readable output (raw for SARIF conversion)
    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    scalafix_action(
        ctx,
        ctx.executable._scalafix,
        files_to_lint,
        ctx.file._config,
        raw_machine_report,
        ctx.attr._java_runtime,
        outputs.machine.exit_code,
        classpath = classpath,
        semanticdb_targetroots = semanticdb_targetroots,
        sourceroot = sourceroot,
    )

    # Convert to SARIF format
    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)

    return [info]

def lint_scalafix_aspect(binary, config, rule_kinds = ["scala_library", "scala_binary", "scala_test"], semantic = False):
    """A factory function to create a linter aspect.

    Args:
        binary: a scalafix executable, provided as a java_binary target
        config: label of the .scalafix.conf configuration file
        rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect
        semantic: If True, enables semantic rules (requires SemanticDB from compilation).
            When enabled, the aspect will access classpath and semanticdb files from the target.
            If SemanticDB files are not available, the aspect falls back to syntactic-only mode.

    Returns:
        An aspect definition for scalafix
    """
    return aspect(
        implementation = _scalafix_aspect_impl,
        # Walk deps for semantic mode to collect transitive classpath
        attr_aspects = ["deps"] if semantic else [],
        attrs = dicts.add(patcher_attrs, {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_scalafix": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config": attr.label(
                default = config,
                allow_single_file = True,
            ),
            "_java_runtime": attr.label(
                default = "@rules_java//toolchains:current_java_runtime",
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
            "_semantic": attr.bool(
                default = semantic,
            ),
        }),
        toolchains = [
            "@bazel_tools//tools/jdk:toolchain_type",
            OPTIONAL_SARIF_PARSER_TOOLCHAIN,
        ],
    )
