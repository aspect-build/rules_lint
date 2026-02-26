# Demo with just running ty from the examples dir:
# $ bazel run --run_under="cd $PWD &&" -- @aspect_rules_lint//lint:ty_bin check src/unsupported_operator.py
a = 10 + "test"
