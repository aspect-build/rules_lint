# Demo with just running bandit $ bazel run --run_under="cd $PWD &&" -- //tools/lint:bandit src/uses_eval.py

print(eval(input("Enter expression: ")))
