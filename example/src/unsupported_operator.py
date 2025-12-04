# Demo with just running ty from the examples dir:
# $ bazel run --run_under="cd $PWD &&" -- //tools/lint:ty check \
#     --config-file=ty.toml src/unsupported_operator.py
a = 10 + "test"
