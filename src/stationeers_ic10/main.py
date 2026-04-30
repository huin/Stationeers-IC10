#!/usr/bin/env python3

import click

from stationeers_ic10 import compile_lua


@click.group()
def main() -> None:
    pass


main.add_command(compile_lua.command)


if __name__ == "__main__":
    main()
