# Demo with just running flake8:
# $ bazel run --run_under="cd $PWD &&" -- :flake8 --config=.flake8 --exit-zero src/*.py
# INFO: Build completed successfully, 1 total action
# src/unused_import.py:6:1: F401 'os' imported but unused
# Error: bazel exited with exit code: 1

# Demo with just running ruff:
# $ bazel run --run_under="cd $PWD &&" -- //tools/lint:ruff check --config=.ruff.toml src/*.py
# INFO: Build completed successfully, 1 total action
# src/unused_import.py:12:8: F401 [*] `os` imported but unused
# Found 1 error.
# [*] 1 potentially fixable with the --fix option.

# Demo with just running pylint:
# $ bazel run --run_under="cd $PWD &&" -- //tools/lint:pylint --rcfile=.pylintrc --reports=n --score=n --msg-template="{path}:{line}:{column}: {msg_id}: {msg}" src/unused_import.py
# src/unused_import.py:17:6: W1302: Invalid format string
# src/unused_import.py:13:0: W0611: Unused import os
import os

# Another lint violation, which is not auto-fixable.
# When running with `--fix` this one should be reported and lint should exit 1.
print("{".format("something"))
