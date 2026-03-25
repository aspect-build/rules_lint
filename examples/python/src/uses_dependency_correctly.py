# Like uses_dependency.py but with correct types, so ty exits 0 when it can
# resolve the workspace import.  Regression test for
# https://github.com/aspect-build/rules_lint/issues/728
from dependency import greet


def main() -> None:
    message: str = greet("World")
    print(message)
