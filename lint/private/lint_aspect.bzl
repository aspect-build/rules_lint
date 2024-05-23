"Helpers to reduce boilerplate for writing linter aspects"

LintOptionsInfo = provider(
    doc = "Global options for running linters",
    fields = {
        "debug": "print additional information for rules_lint developers",
        "fail_on_violation": "whether to honor the exit code of linter tools run as actions",
        "fix": "whether to run linters in their --fix mode. Fixes are collected into patch files.",
    },
)

def _lint_options_impl(ctx):
    return LintOptionsInfo(
        debug = ctx.attr.debug,
        fail_on_violation = ctx.attr.fail_on_violation,
        fix = ctx.attr.fix,
    )

lint_options = rule(
    implementation = _lint_options_impl,
    attrs = {
        "debug": attr.bool(),
        "fix": attr.bool(),
        "fail_on_violation": attr.bool(),
    },
)

_OUTFILE_FORMAT = "{label}.aspect_rules_lint.{mnemonic}.{suffix}"

# buildifier: disable=function-docstring
def report_files(mnemonic, target, ctx):
    report = ctx.actions.declare_file(_OUTFILE_FORMAT.format(label = target.label.name, mnemonic = mnemonic, suffix = "report"))
    outs = [report]
    if ctx.attr._options[LintOptionsInfo].fail_on_violation:
        # Fail on violation means the exit code is reported to Bazel as the action result
        exit_code = None
    else:
        # The exit code should instead be provided as an action output so the build succeeds.
        # Downstream tooling like `aspect lint` will be responsible for reading the exit codes
        # and interpreting them.
        exit_code = ctx.actions.declare_file(_OUTFILE_FORMAT.format(label = target.label.name, mnemonic = mnemonic, suffix = "exit_code"))
        outs.append(exit_code)
    return report, exit_code, OutputGroupInfo(rules_lint_report = depset(outs))

def patch_file(mnemonic, target, ctx):
    patch = ctx.actions.declare_file(_OUTFILE_FORMAT.format(label = target.label.name, mnemonic = mnemonic, suffix = "patch"))
    return patch, OutputGroupInfo(rules_lint_patch = depset([patch]))

# If we return multiple OutputGroupInfo from a rule implementation, only one will get used.
# So we need a separate function to return both.
def patch_and_report_files(*args):
    patch, _ = patch_file(*args)
    report, exit_code, _ = report_files(*args)
    return patch, report, exit_code, OutputGroupInfo(
        rules_lint_report = depset([f for f in [report, exit_code] if f]),
        rules_lint_patch = depset([patch]),
    )

def filter_srcs(rule):
    if "lint-genfiles" in rule.attr.tags:
        return rule.files.srcs
    else:
        return [s for s in rule.files.srcs if s.is_source]
