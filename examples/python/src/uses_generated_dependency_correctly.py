from generated_dependency import greet


def main() -> None:
    message: str = greet("World")
    print(message)
