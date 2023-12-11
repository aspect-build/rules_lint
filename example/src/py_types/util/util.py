"""
This module mostly/entirely exists to be imported by other packages in the workspace,
to test MyPy imports functionality is working.
"""


from typing import List, TypeVar

T = TypeVar("T")


def flatten_lists(l: List[List[T]]) -> List[T]:
    flat_list = []
    for sublist in l:
        for item in sublist:
            flat_list.append(item)
    return flat_list
