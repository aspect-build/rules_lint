"Unit tests for mypy starlark code."

load("@rules_testing//lib:analysis_test.bzl", "analysis_test", "test_suite")
load("@rules_testing//lib:util.bzl", "util")
load("//lint:mypy.bzl", "MypyInfo", "mypy_action", "mypy_aspect")

def _mypy_impl(ctx):
    mypy_info = mypy_action(ctx, ctx.executable._mypy, ctx.files.srcs, ctx.attr.deps, ctx.files.configs)
    return mypy_info

_aspect = mypy_aspect("//lint/test:mypy_fake", [])

# A dummy rule acting as a test fixture for the action factory function
mypy_rule = rule(
    implementation = _mypy_impl,
    attrs = {
        "srcs": attr.label_list(doc = "python source files", allow_files = True),
        "deps": attr.label_list(doc = "py_library rules", aspects = [_aspect]),
        "configs": attr.label_list(doc = "mypy.ini files", allow_files = True),
        "rules_lint_verbose": attr.bool(),
        "_mypy": attr.label(
            default = "//lint/test:mypy_fake",
            executable = True,
            cfg = "exec",
        ),
    },
)

def _test_simple(name):
    util.helper_target(
        native.py_library,
        name = name + "_trans",
        srcs = ["lib2.py"],
    )
    util.helper_target(
        native.py_library,
        name = name + "_lib",
        srcs = ["lib.py"],
        deps = [name + "_trans"],
    )
    util.helper_target(
        mypy_rule,
        name = name + "_mypy",
        srcs = ["app.py"],
        configs = ["mypy.ini", "mypy.ini.2"],
        deps = [name + "_lib"],
    )
    analysis_test(
        name = name,
        impl = _simple_assertions,
        target = name + "_mypy",
    )

def _simple_assertions(env, target):
    action = env.expect.that_target(target).action_named("mypy")
    action.argv().contains("--bazel")
    action.inputs().contains_at_least([
        # Direct sources are inputs
        "lint/test/app.py",
        # Transitive sources are needed by mypy too
        "lint/test/lib.py",
        "lint/test/lib2.py",
        # config-map for transitive 1p source files are passed so mypy can read their types
        "lint/test/lib.data.json",
        "lint/test/lib.meta.json",
        "lint/test/lib2.data.json",
        "lint/test/lib2.meta.json",
        # All config files are passed, even those we don't expect mypy will read
        "lint/test/mypy.ini",
        "lint/test/mypy.ini.2",
    ])

    # TODO: assert on the content of this provider
    env.expect.that_target(target).has_provider(MypyInfo)

def mypy_test_suite(name):
    test_suite(
        name = name,
        tests = [
            _test_simple,
        ],
    )
