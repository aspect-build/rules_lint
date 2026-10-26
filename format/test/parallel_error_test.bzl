"""Unit tests for parallel_error, which checks format_multirun's parallel argument."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//format/private:formatter_binary.bzl", "parallel_error")

_KWARGS = {"go": None, "protocol_buffer": ":buf", "python": ":ruff", "shell": ":shfmt"}

def _valid_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, None, parallel_error([], _KWARGS))
    asserts.equals(env, None, parallel_error(["python", "shell"], _KWARGS))
    return unittest.end(env)

def _errors_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.true(env, parallel_error("python", _KWARGS).startswith("parallel must be a list"))
    asserts.equals(env, "parallel entries must be strings, got 1", parallel_error(["python", 1], _KWARGS))
    asserts.true(env, parallel_error(["cpp"], _KWARGS).startswith("parallel names cpp, which is not a language attribute."))

    # go is set to None, so it has no formatter, like a language that is left out.
    asserts.equals(
        env,
        "parallel names go, which has no formatter set. Languages with formatters: [\"python\", \"shell\", \"protocol_buffer\"]",
        parallel_error(["go"], _KWARGS),
    )
    asserts.true(env, parallel_error(["cc"], _KWARGS).startswith("parallel names cc, which has no formatter"))
    asserts.equals(env, "parallel lists python more than once", parallel_error(["python", "python"], _KWARGS))
    asserts.true(env, parallel_error(["protocol_buffer"], _KWARGS).startswith("parallel names protocol_buffer, whose formatter format.sh runs once per file"))
    return unittest.end(env)

valid_test = unittest.make(_valid_test_impl)
errors_test = unittest.make(_errors_test_impl)

def parallel_error_test_suite(name):
    unittest.suite(name, valid_test, errors_test)
