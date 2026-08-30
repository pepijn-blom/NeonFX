"""Convert cli.env.sh bash exports into fish set --global lines."""

from __future__ import annotations

import re
import sys
from pathlib import Path

EXPORT_RE = re.compile(r"^export ([A-Za-z_][A-Za-z0-9_]+)='(.*)'\s*$")


def parse_exports(text):
    values = {}
    for line in text.splitlines():
        match = EXPORT_RE.match(line)
        if match:
            values[match.group(1)] = match.group(2)
    return values


def to_fish(values):
    lines = ["# eza, fzf, jq — generated from cli.env.sh"]
    for key, value in values.items():
        escaped = value.replace("'", "'\\''")
        lines.append(f"set --global {key} '{escaped}'")
    return "\n".join(lines) + "\n"


def fish_from_file(cli_env_path):
    return to_fish(parse_exports(Path(cli_env_path).read_text()))


def main(argv):
    if len(argv) < 3 or argv[1] != "fish":
        print("Usage: cli_env.py fish <cli.env.sh>", file=sys.stderr)
        return 2
    sys.stdout.write(fish_from_file(argv[2]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
