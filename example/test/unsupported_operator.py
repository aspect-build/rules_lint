# Demo with just running ty:
# $ bazel run --run_under="cd $PWD &&" -- @aspect_rules_lint//lint:ty_bin check --config-file=ty.toml test/*.py
a = 10 + "test"
