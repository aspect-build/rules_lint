# Demo with just running ty:
# $ bazel run --run_under="cd $PWD &&" -- @aspect_rules_lint//lint:ty_bin check --config-file=ty.toml src/call_non_callable.py
B = 1
# This error should be ignored, as it is specified as ignored in ty.toml
B()
