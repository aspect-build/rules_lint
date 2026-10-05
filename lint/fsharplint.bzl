"""API for declaring an FSharpLint lint aspect that visits fsharp_{binary|library|test} rules.

Typical usage:

FSharpLint is distributed as the [dotnet-fsharplint](https://www.nuget.org/packages/dotnet-fsharplint)
.NET tool, so install it "in userland" with rules_dotnet and Paket, the same way as Fantomas.
Add it to your `paket.dependencies`:

```
nuget dotnet-fsharplint 0.27.0
```

Then run `paket install` and `paket2bazel` to regenerate the Bazel repository, which provides
`@paket.main//dotnet-fsharplint/tools:dotnet-fsharplint`.

Next, create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:fsharplint.bzl", "lint_fsharplint_aspect")

fsharplint = lint_fsharplint_aspect(
    binary = Label("@paket.main//dotnet-fsharplint/tools:dotnet-fsharplint"),
    config = Label("//:fsharplint.json"),
)
```

FSharpLint reads `fsharplint.json` from its working directory when run outside Bazel, so keeping
the config at the repository root gives the same results in both places.
See https://fsprojects.github.io/FSharpLint/how-tos/rule-configuration.html

Note that the FSharpLint CLI lints a single `.fs` or `.fsx` file at a time, typechecking it on its own
as if it were a script, rather than through the `.fsproj` that it would normally be given.
Rules that rely on type information may therefore report less than they would for a whole project.
Each source file is linted in its own action.
"""

load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "should_visit")

_MNEMONIC = "AspectRulesLintFSharpLint"

# FSharpLint prints progress and a recommendation to lint a project instead of a file,
# none of which describes a violation.
# These may be preceded by ANSI color codes, and on stderr by "FSharpLint error: " in the msbuild format.
_NOISE_PATTERN = "^($esc\\[[0-9;]*m)*(FSharpLint error: )?(Running FSharpLint with |WARNING: Going to analyze single |========== )"

# Lines holding nothing but ANSI color codes, which FSharpLint emits when it resets the color.
_COLOR_ONLY_PATTERN = "^($esc\\[[0-9;]*m)*$"

def fsharplint_action(ctx, executable, srcs, config, stdout, exit_code = None, format = "standard", color = False):
    """Run FSharpLint as an action under Bazel.

    Based on https://fsprojects.github.io/FSharpLint/how-tos/install-dotnet-tool.html

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: struct with a `_fsharplint` field, typically `ctx.executable`
        srcs: a single-element list with the `.fs` or `.fsx` file to lint, as FSharpLint accepts one file per run
        config: the fsharplint.json file, or None to use FSharpLint's default rules
        stdout: output file containing the stdout and stderr of FSharpLint
        exit_code: output file containing the exit code of FSharpLint.
            If None, then fail the build when FSharpLint exits non-zero.
            FSharpLint exits -1 both when it reports warnings and when it fails to lint.
        format: FSharpLint's `--format`, either `standard` or `msbuild`
        color: whether to keep FSharpLint's colors when its output is redirected to a file
    """
    if len(srcs) != 1:
        fail("FSharpLint lints one file at a time, but got {}".format(srcs))

    inputs = list(srcs)
    outputs = [stdout]

    # Wire command-line options, see `dotnet fsharplint --help`
    args = ctx.actions.args()
    args.add("--format", format)
    args.add("lint")
    if config:
        inputs.append(config)
        args.add("--lint-config", config)
    args.add_all(srcs)

    env = {
        "DOTNET_CLI_TELEMETRY_OPTOUT": "1",
        "DOTNET_NOLOGO": "1",
    }
    if color:
        # .NET looks up the color codes in the terminfo database for $TERM, which is unset in actions.
        env["DOTNET_SYSTEM_CONSOLE_ALLOW_ANSI_COLOR_REDIRECTION"] = "1"
        env["TERM"] = "xterm-256color"

    command = [
        "esc=$(printf '\\033')",
        "{fsharplint} \"$@\" 2>&1 | grep -v -E \"{noise}\" >{stdout}",
        "code=${{PIPESTATUS[0]}}",
        # Leave no report at all when there is nothing but color resets left in it
        "grep -q -v -E \"{color_only}\" {stdout} || : >{stdout}",
    ]
    if exit_code:
        command.append("echo $code >{exit_code}")
        outputs.append(exit_code)
    else:
        command.append("if [ $code -ne 0 ]; then cat {stdout} >&2; exit $code; fi")

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        tools = [executable._fsharplint],
        command = "\n".join(command).format(
            fsharplint = executable._fsharplint.path,
            noise = _NOISE_PATTERN,
            color_only = _COLOR_ONLY_PATTERN,
            stdout = stdout.path,
            exit_code = exit_code.path if exit_code else None,
        ),
        arguments = [args],
        env = env,
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{{label}}:{} with FSharpLint".format(srcs[0].basename),
    )

def _filter_srcs(rule):
    # Signature files are left out: FSharpLint would lint the path itself as F# source code.
    return [s for s in filter_srcs(rule) if s.extension in ["fs", "fsx"]]

# buildifier: disable=function-docstring
def _fsharplint_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []

    files_to_lint = _filter_srcs(ctx.rule)

    if len(files_to_lint) == 0:
        outputs, info = output_files(_MNEMONIC, target, ctx)
        noop_lint_action(ctx, outputs)
        return [info]

    outputs, info = output_files(_MNEMONIC, target, ctx, files_to_lint = files_to_lint)
    color = ctx.attr._options[LintOptionsInfo].color

    for output, file in zip(outputs, files_to_lint):
        fsharplint_action(ctx, ctx.executable, [file], ctx.file._config, output.human.out, output.human.exit_code, color = color)

        # The msbuild format prints one line per violation, which the SARIF parser understands.
        raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name + "_rules_lint/" + file.short_path, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
        fsharplint_action(ctx, ctx.executable, [file], ctx.file._config, raw_machine_report, output.machine.exit_code, format = "msbuild")
        parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, output.machine.out)

    return [info]

def lint_fsharplint_aspect(binary, config = None, rule_kinds = ["fsharp_binary", "fsharp_library", "fsharp_test"]):
    """A factory function to create a linter aspect.

    Args:
        binary: a dotnet-fsharplint executable, typically `@paket.main//dotnet-fsharplint/tools:dotnet-fsharplint`
        config: label of the fsharplint.json file.
            If None, FSharpLint's default rules are used.
            Note that FSharpLint does not merge this with its defaults: any rule left out of the file is disabled.
        rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect

    Returns:
        An aspect definition for FSharpLint
    """
    return aspect(
        implementation = _fsharplint_aspect_impl,
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_fsharplint": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config": attr.label(
                default = config,
                allow_single_file = True,
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
        toolchains = [OPTIONAL_SARIF_PARSER_TOOLCHAIN],
    )
