"A lint_test whose aspect reports violations for targets named dirty_*, to test the JUnit XML"

load("//lint:lint_test.bzl", "lint_test")

# Coloured, and containing characters that need escaping in XML.
_REPORT = "\033[1mfile.py:1:1\033[0m: error <&> \"quoted\" ]]> end\n"

def _fake_lint_aspect_impl(target, ctx):
    dirty = target.label.name.startswith("dirty_")
    out = ctx.actions.declare_file(target.label.name + ".fake_lint.out")
    exit_code = ctx.actions.declare_file(target.label.name + ".fake_lint.exit_code")
    ctx.actions.write(out, _REPORT if dirty else "")
    ctx.actions.write(exit_code, "1" if dirty else "0")
    return [OutputGroupInfo(rules_lint_human = depset([out, exit_code]))]

_fake_lint_aspect = aspect(implementation = _fake_lint_aspect_impl)

fake_lint_test = lint_test(aspect = _fake_lint_aspect)
