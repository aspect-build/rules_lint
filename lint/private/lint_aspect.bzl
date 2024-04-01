"Helpers to reduce boilerplate for writing linter aspects"

LintOptionsInfo = provider(
    doc = "Global options for running linters",
    fields = {"fail_on_violation": "whether to honor the exit code of linter tools run as actions"},
)

def _fail_on_violation_flag_impl(ctx):
    return LintOptionsInfo(fail_on_violation = ctx.build_setting_value)

fail_on_violation_flag = rule(
    implementation = _fail_on_violation_flag_impl,
    build_setting = config.bool(flag = True),
)

def report_file(mnemonic, target, ctx):
    report = ctx.actions.declare_file("{}.{}.aspect_rules_lint.report".format(mnemonic, target.label.name))
    return report, OutputGroupInfo(rules_lint_report = depset([report]))

def patch_file(mnemonic, target, ctx):
    patch = ctx.actions.declare_file("{}.{}.aspect_rules_lint.patch".format(mnemonic, target.label.name))
    return patch, OutputGroupInfo(rules_lint_patch = depset([patch]))

# If we return multiple OutputGroupInfo from a rule implementation, only one will get used.
# So we need a separate function to return both.
def patch_and_report_files(*args):
    patch, _ = patch_file(*args)
    report, _ = report_file(*args)
    return patch, report, OutputGroupInfo(
        rules_lint_report = depset([report]),
        rules_lint_patch = depset([patch]),
    )

def filter_srcs(rule):
    if "lint-genfiles" in rule.attr.tags:
        return rule.files.srcs
    else:
        return [s for s in rule.files.srcs if s.is_source]
