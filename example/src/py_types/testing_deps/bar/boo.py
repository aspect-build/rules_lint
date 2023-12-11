from typing import List


def boo_func(the_thing: List[str]) -> None:
    for item in the_thing:
        print(f"What you gave me has a(n) {item}.")
