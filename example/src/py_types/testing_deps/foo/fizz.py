from typing import Callable, List


def fizz_filterer(things: List[str], filter_func: Callable[[str], bool]) -> List[str]:
    filtered_list: List[str] = []
    for item in things:
        if filter_func(item):
            filtered_list.append(item)
    return filtered_list
