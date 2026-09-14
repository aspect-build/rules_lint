# Demonstrates that type definitions provided via lint_ty_aspect(types = [...])
# are resolved by ty without requiring the library in target deps.
from dependency import greet


def main() -> None:
    message: str = greet("World")
    print(message)

