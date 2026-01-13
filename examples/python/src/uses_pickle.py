# Demo for semgrep
# $ bazel run --run_under="cd $PWD &&" -- //tools/lint:semgrep -- scan --error src/*.py

import os
import pickle

with open(os.devnull, "wb") as f:
    pickle.dump(None, f)
