"Allow rules_python gazelle to generate a macro that runs pytest as the main"

load("@aspect_rules_py//py:defs.bzl", _py_test = "py_test")

def py_test(name, deps = [], **kwargs):
    _py_test(
        name = name,
        pytest_main = True,
        deps = deps + ["@pip//pytest"],
        **kwargs
    )
