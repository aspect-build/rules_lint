# Demo with just running flake8:
# $ bazel run --run_under="cd $PWD &&" -- :flake8 --config=.flake8 --exit-zero src/*.py
# INFO: Build completed successfully, 1 total action
# src/unused_import.py:6:1: F401 'os' imported but unused
# Error: bazel exited with exit code: 1

# Demo with just running ruff:
# $ bazel run --run_under="cd $PWD &&" -- :ruff --config=.ruff.toml --exit-zero src/*.py
# INFO: Build completed successfully, 1 total action
# src/unused_import.py:12:8: F401 [*] `os` imported but unused
# Found 1 error.
# [*] 1 potentially fixable with the --fix option.

# Demo of running pyright:
# $ bazel run --run_under="cd $PWD &&" -- tools:pyright src/unused_import.py
import os

b: int = 3.4  # Error
