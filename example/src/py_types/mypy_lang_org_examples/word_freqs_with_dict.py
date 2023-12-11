# Display the frequencies of words in a file.

import sys
import re
from typing import Dict

if not sys.argv[1:]:
    raise RuntimeError("Usage: wordfreq FILE")

d = {}  # type: Dict[str, int]

with open(sys.argv[1]) as f:
    for s in f:
        for word in re.sub("\W", " ", s).split():
            d[word] = d.get(word, 0) + 1

# Use list comprehension
l = [(freq, word) for word, freq in d.items()]

for freq, word in sorted(l):
    print("%-6d %s" % (freq, word))
