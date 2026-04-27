#!/usr/bin/env python3
import itertools
import re
import subprocess
import sys
from pathlib import Path
from typing import Iterator, Sequence

import click


@click.group()
def main() -> None:
    pass


_COMMENT_RX = re.compile(r"--[-]*([^\n]*)")
_INCLUDE_RX = re.compile(r"-- include:(.+)")


@main.command()
@click.option(
    "--display",
    is_flag=True,
    help="Display instead of copying to clipboard.",
)
@click.option(
    "--strip",
    is_flag=True,
    help="Strip out comments and blank lines.",
)
@click.option(
    "-I",
    "--include-dir",
    type=Path,
    multiple=True,
)
@click.argument(
    "input_source",
    type=Path,
)
def compile_lua(
    display: bool,
    strip: bool,
    input_source: Path,
    include_dir: list[Path],
) -> None:
    compiler = Compiler(
        strip=strip,
        include_dirs=include_dir,
    )

    out_lines = compiler.process_file(
        file_path=input_source,
    )

    if display:
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


class Compiler:
    _strip: bool
    _include_dirs: list[Path]

    def __init__(
        self,
        strip: bool,
        include_dirs: Sequence[Path],
    ) -> None:
        self._strip = strip
        self._include_dirs = list(include_dirs)

    def process_file(
        self,
        file_path: Path,
    ) -> Iterator[str]:
        return self._process_file(
            file_path=file_path.absolute(),
            parent_files=set(),
        )

    def _process_file(
        self,
        file_path: Path,
        parent_files: set[Path],
    ) -> Iterator[str]:
        if file_path in parent_files:
            raise click.ClickException(f"Recusive include found to {file_path}")

        with file_path.open("r") as in_file:
            for line in in_file:
                if match := _INCLUDE_RX.fullmatch(line.rstrip()):
                    yield from self._include_file(
                        file_path=Path(match.group(1)),
                        parent_file=file_path,
                        parent_files=parent_files,
                    )
                    continue

                if self._strip:
                    if comment := _COMMENT_RX.search(line):
                        line = line[: comment.start()]
                    if not line.rstrip():
                        continue
                yield line

    def _include_file(
        self,
        file_path: Path,
        parent_file: Path,
        parent_files: set[Path],
    ) -> Iterator[str]:
        if not file_path.is_absolute():
            for dir in itertools.chain([parent_file.parent], self._include_dirs):
                candidate_path = dir / file_path
                if candidate_path.exists():
                    file_path = candidate_path
                    break
            else:
                raise click.ClickException(
                    f"Could not find file {file_path} included by {parent_file}"
                )

        return self._process_file(
            file_path=file_path.absolute(),
            parent_files=parent_files | {parent_file},
        )


if __name__ == "__main__":
    main()
