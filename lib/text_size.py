"""Ghostty-only font size helpers for the Neon FX sliders and Style menu."""

from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

FONT_SIZE_MIN = 6
FONT_SIZE_MAX = 18
FONT_SIZE_DEFAULT = 9
GHOSTTY_CONFIG = os.path.expanduser("~/.config/ghostty/config")
FONT_SIZE_LINE = re.compile(r"^font-size\s*=\s*([0-9]+(?:\.[0-9]+)?)\s*$")


class _Result:
    def __init__(self, returncode=0, stderr=b"", stdout=b""):
        self.returncode = returncode
        self.stderr = stderr
        self.stdout = stdout


def clamp_font_size(value):
    try:
        size = int(round(float(value)))
    except (TypeError, ValueError):
        return FONT_SIZE_DEFAULT
    return max(FONT_SIZE_MIN, min(FONT_SIZE_MAX, size))


def read_ghostty_font_size(path=None):
    config_path = Path(path) if path is not None else Path(GHOSTTY_CONFIG)
    if not config_path.is_file():
        return None
    try:
        lines = config_path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return None
    for line in lines:
        match = FONT_SIZE_LINE.match(line.strip())
        if match:
            return clamp_font_size(match.group(1))
    return None


def current_font_size(path=None):
    size = read_ghostty_font_size(path)
    return FONT_SIZE_DEFAULT if size is None else size


def write_ghostty_font_size(size, path):
    size = clamp_font_size(size)
    config_path = Path(path)
    try:
        lines = config_path.read_text(encoding="utf-8").splitlines() if config_path.is_file() else []
    except OSError:
        lines = []
    out = []
    replaced = False
    for line in lines:
        if FONT_SIZE_LINE.match(line.strip()):
            out.append(f"font-size = {size}")
            replaced = True
        else:
            out.append(line)
    if not replaced:
        if out and out[-1] != "":
            out.append("")
        out.append(f"font-size = {size}")
    config_path.parent.mkdir(parents=True, exist_ok=True)
    config_path.write_text("\n".join(out) + "\n", encoding="utf-8")
    return size


def reload_ghostty():
    subprocess.run(["pkill", "-SIGUSR2", "ghostty"], capture_output=True, check=False)


def apply_font_size(pt, config_path=None, reloader=None):
    path = Path(config_path) if config_path is not None else Path(GHOSTTY_CONFIG)
    try:
        write_ghostty_font_size(pt, path)
    except OSError as exc:
        return _Result(1, str(exc).encode())
    if reloader is None:
        reloader = reload_ghostty
    reloader()
    return _Result(0)
