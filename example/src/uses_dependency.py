# Demo with just running ty from the examples dir:
# $ bazel build --aspects=//tools/lint:linters.bzl%ty //src:uses_dependency
from python_lib.dependency import greet


def main() -> None:
    """Main function that uses the dependency."""
    # This should cause a type error if transitive deps are NOT available
    # because ty won't know that greet() returns a str
    message: int = greet("World")  # Type error: str is not compatible with int
    print(message)
