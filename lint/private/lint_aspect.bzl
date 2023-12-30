"Helpers to reduce boilerplate for writing linter aspects"

def report_file(mnemonic, target, ctx):
    report = ctx.actions.declare_file("{}.{}.aspect_rules_lint.report".format(mnemonic, target.label.name))
    info = OutputGroupInfo(rules_lint_report = depset([report]))
    return report, info

def patch_file(mnemonic, target, ctx):
    patch = ctx.actions.declare_file("{}.{}.aspect_rules_lint.patch".format(mnemonic, target.label.name))
    info = OutputGroupInfo(rules_lint_patch = depset([patch]))
    return patch, info
