# Demo with just running flake8:
# $ bazel run --run_under="cd $PWD &&" -- :flake8 --config=.flake8 --exit-zero src/*.py
# INFO: Build completed successfully, 1 total action
# src/unused_import.py:6:1: F401 'os' imported but unused
# Error: bazel exited with exit code: 1
import os
