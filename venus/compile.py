#!/usr/bin/env python3
import subprocess
from typing import Iterator
import sys
from pathlib import Path
import argparse
import re

_INCLUDE_RX = re.compile(r"-- include:(.+)")


def main() -> None:
    argparser = argparse.ArgumentParser()
    argparser.add_argument("input", type=Path)
    argparser.add_argument("--display", action="store_true")
    args = argparser.parse_args()

    out_lines = _process_file(args.input, set())

    if args.display:
        for line in out_lines:
            sys.stdout.write(line)
    else:
        output = "".join(out_lines)
        copier = subprocess.Popen(
            ["wl-copy"],
            stdin=subprocess.PIPE,
            stdout=None,
            stderr=None,
            text=True,
        )
        copier.communicate(output)


def _process_file(
    file_path: Path,
    parent_files: set[Path],
) -> Iterator[str]:
    if file_path in parent_files:
        raise ValueError(f"Recusive include found to {file_path}")
    with file_path.open("r") as in_file:
        for line in in_file:
            if match := _INCLUDE_RX.fullmatch(line.rstrip()):
                yield from _process_file(
                    Path(match.group(1)), parent_files | {file_path}
                )
            else:
                yield line


if __name__ == "__main__":
    main()
