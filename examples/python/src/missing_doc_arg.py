# Demo with just running pydoclint:
# $ bazel run --run_under="cd $PWD &&" -- //tools/lint:pydoclint --config=pyproject.toml src/missing_doc_arg.py

def documented_add(value: int, extra: int) -> int:
    """Add two numbers.

    Args:
        value (int): Base value.

    Returns:
        int: Sum of both arguments.
    """
    return value + extra
