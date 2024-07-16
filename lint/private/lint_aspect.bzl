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

def should_visit(rule, allow_kinds, allow_filegroup_tags = []):
    """Determine whether a rule is meant to be visited by a linter aspect

    Args:
        rule: a [rules_attributes](https://bazel.build/rules/lib/builtins/rule_attributes.html) object
        allow_kinds (list of string): return true if the rule's kind is in the list
        allow_filegroup_tags (list of string): return true if the rule is a filegroup and has a tag in this list

    Returns:
        whether to apply the aspect on this rule
    """
    if rule.kind in allow_kinds:
        return True
    if rule.kind == "filegroup":
        for allow_tag in allow_filegroup_tags:
            if allow_tag in rule.attr.tags:
                return True
    return False

_OUTFILE_FORMAT = "{label}.{mnemonic}.{suffix}"

def report_files(mnemonic, target, ctx):
    """Declare linter output files.

    Args:
        mnemonic: used as part of the filename
        target: the target being visited by a linter aspect
        ctx: the aspect context

    Returns:
        4-tuple of output (human-readable stdout), report (machine-parsable), exit code of the tool, and the OutputGroupInfo provider
    """
    output = ctx.actions.declare_file(_OUTFILE_FORMAT.format(label = target.label.name, mnemonic = mnemonic, suffix = "txt"))
    report = ctx.actions.declare_file(_OUTFILE_FORMAT.format(label = target.label.name, mnemonic = mnemonic, suffix = "report"))
    outs = [output, report]
    if ctx.attr._options[LintOptionsInfo].fail_on_violation:
        # Fail on violation means the exit code is reported to Bazel as the action result
        exit_code = None
    else:
        # The exit code should instead be provided as an action output so the build succeeds.
        # Downstream tooling like `aspect lint` will be responsible for reading the exit codes
        # and interpreting them.
        exit_code = ctx.actions.declare_file(_OUTFILE_FORMAT.format(label = target.label.name, mnemonic = mnemonic, suffix = "exit_code"))
        outs.append(exit_code)

    return output, report, exit_code, OutputGroupInfo(
        rules_lint_output = depset([output]),
        rules_lint_report = depset([f for f in [report, exit_code] if f]),
    )

def patch_file(mnemonic, target, ctx):
    patch = ctx.actions.declare_file(_OUTFILE_FORMAT.format(label = target.label.name, mnemonic = mnemonic, suffix = "patch"))
    return patch, OutputGroupInfo(rules_lint_patch = depset([patch]))

# If we return multiple OutputGroupInfo from a rule implementation, only one will get used.
# So we need a separate function to return both.
def patch_and_report_files(*args):
    patch, _ = patch_file(*args)
    output, report, exit_code, _ = report_files(*args)
    return patch, output, report, exit_code, OutputGroupInfo(
        rules_lint_output = depset([output]),
        rules_lint_report = depset([f for f in [report, exit_code] if f]),
        rules_lint_patch = depset([patch]),
    )

def filter_srcs(rule):
    if "lint-genfiles" in rule.attr.tags:
        return rule.files.srcs
    else:
        return [s for s in rule.files.srcs if s.is_source]

def dummy_successful_lint_action(ctx, stdout, exit_code = None, patch = None):
    """Dummy action for creating expected outputs when no files are provided to a lint action.

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        stdout: output file that will be empty
        exit_code: output file containing 0 exit code.
            If None, continue successfully
        patch: output file for the patch
            If None, continue successfully
    """
    inputs = []
    outputs = [stdout]

    command = "touch {stdout}".format(stdout = stdout.path)

    if exit_code:
        command += " && echo 0 > {exit_code}".format(exit_code = exit_code.path)
        outputs.append(exit_code)

    if patch:
        command += " && touch {patch}".format(patch = patch.path)
        outputs.append(patch)

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        command = command,
    )
