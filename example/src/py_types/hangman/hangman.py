#!/usr/bin/python3

"""
Code is from https://gist.github.com/eaorak/3986188.
Demonstrates very basic Python typing.
"""

import random
from typing import Optional, List, Tuple


class HangMan(object):
    hang: List[str] = [
        " +---+",
        " |   |",
        "     |",
        "     |",
        "     |",
        "     |",
        "=======",
    ]

    man = {}
    man[0] = [" 0   |"]
    man[1] = [" 0   |", " |   |"]
    man[2] = [" 0   |", "/|   |"]
    man[3] = [" 0   |", "/|\\  |"]
    man[4] = [" 0   |", "/|\\  |", "/    |"]
    man[5] = [" 0   |", "/|\\  |", "/ \\  |"]

    pics: List[List[str]] = []

    words = """ant baboon badger bat bear beaver camel cat clam cobra cougar coyote
crow deer dog donkey duck eagle ferret fox frog goat goose hawk lion lizard llama
mole monkey moose mouse mule newt otter owl panda parrot pigeon python rabbit ram
rat raven rhino salmon seal shark sheep skunk sloth snake spider stork swan tiger
toad trout turkey turtle weasel whale wolf wombat zebra""".split()

    infStr = "_-*'*-_-*'*-_-*'*-_-*'*-_-*'*-_-*'*-_-*'*-_-*'*-_-*'*-_-*'"

    def __init__(self) -> None:
        i, j = 2, 0
        self.pics.append(self.hang[:])
        for ls in self.man.values():
            pic, j = self.hang[:], 0
            for m in ls:
                pic[i + j] = m
                j += 1
            self.pics.append(pic)

    def pick_word(self) -> str:
        return self.words[random.randint(0, len(self.words) - 1)]

    def print_pic(self, idx: int) -> None:
        for line in self.pics[idx]:
            print(line)

    def ask_and_evaluate(
        self, word: List[str], result: List[str], missed: List[str]
    ) -> Tuple[Optional[str], bool]:
        guess = input()
        if guess is None or len(guess) != 1 or (guess in result) or (guess in missed):
            return None, False
        i = 0
        right = guess in word
        for c in word:
            if c == guess:
                result[i] = c
            i += 1
        return guess, right

    def info(self, info: str) -> None:
        print(self.infStr[:-3])
        print(info)
        print(self.infStr[3:])

    def start(self) -> None:
        print("Welcome to Hangman !")
        word = list(self.pick_word())
        result = list("*" * len(word))
        print("The word is: ", result)
        success, i = False, 0
        missed: List[str] = []
        while i < len(self.pics) - 1:
            print("Guess the word: ", end="")
            guess, right = self.ask_and_evaluate(word, result, missed)
            if guess is None:
                print("You've already entered this character.")
                continue
            print("".join(result))
            if result == word:
                self.info("Congratulations ! You've just saved a life !")
                success = True
                break
            if not right:
                missed.append(guess)
                i += 1
            self.print_pic(i)
            print("Missed characters: ", missed)

        if not success:
            self.info(
                "The word was '" + "".join(word) + "' ! You've just killed a man, yo !"
            )


if __name__ == "__main__":
    HangMan().start()
