# Demo with just running ty:
# $ ./lint.sh src:call_non_callable
B = 1
# This error should be ignored, as it is specified as ignored in src/ty.toml
B()
