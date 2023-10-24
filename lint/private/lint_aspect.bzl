"Helpers to reduce boilerplate for writing linter aspects"

def report_file(target, ctx):
    report = ctx.actions.declare_file(target.label.name + ".aspect_rules_lint.report")
    info = OutputGroupInfo(rules_lint_report = depset([report]))
    return report, info
