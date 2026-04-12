import os
import sys
from pydoclint import main


def _run() -> int:
    color = True if os.environ.get("FORCE_COLOR") == "1" else None
    return main.main(args=sys.argv[1:], prog_name="pydoclint", color=color)


if __name__ == "__main__":
    sys.exit(_run())
