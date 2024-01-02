"Helpers to reduce boilerplate for writing linter aspects"

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
