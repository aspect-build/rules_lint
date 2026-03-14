import os
import subprocess
import sys
from pathlib import Path

import PySide6


def main() -> None:
    workspace = os.environ.get("BUILD_WORKSPACE_DIRECTORY")
    if workspace:
        os.chdir(workspace)

    pyside_file = PySide6.__file__

    tool_name = "qmllint.exe" if sys.platform == "win32" else "qmllint"
    tool_path = Path(pyside_file).parent / tool_name
    if not tool_path.is_file():
        print("Error: qmllint executable not found in PySide6 package.")  # noqa: T201
        sys.exit(1)

    result = subprocess.run([str(tool_path), *sys.argv[1:]], check=False)  # noqa: S603
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
