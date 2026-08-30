"""Merge or remove the Neon FX Quickshell menu entry."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def load_jsonc(path):
    return load_jsonc_from_string(Path(path).read_text())


def load_jsonc_from_string(text):
    stripped = []
    for line in text.splitlines():
        if line.lstrip().startswith("//"):
            continue
        stripped.append(line)
    cleaned = "\n".join(stripped)
    cleaned = re.sub(r",(\s*[}\]])", r"\1", cleaned)
    return json.loads(cleaned)


def _is_neon_key(key):
    key = str(key)
    return (
        key == "style.neon"
        or key.startswith("style.neon.")
        or key == "style.font-size"
        or key.startswith("style.font-size.")
    )


def update_menu_jsonc(dest_path, mode, source_path=""):
    dest = Path(dest_path)
    dest.parent.mkdir(parents=True, exist_ok=True)
    data = {}
    if dest.exists() and dest.read_text().strip():
        data = load_jsonc(dest)

    if mode == "install":
        if not source_path:
            raise ValueError("install requires a source jsonc path")
        source = load_jsonc(source_path)
        neon = {key: value for key, value in source.items() if _is_neon_key(key)}
        if "style.neon" not in neon:
            raise ValueError(f"No style.neon entry in {source_path}")
        data.update(neon)
    elif mode == "remove":
        for key in list(data):
            if _is_neon_key(key):
                data.pop(key)
    else:
        raise ValueError(f"Unknown mode: {mode}")

    dest.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    return data


def main(argv):
    if len(argv) < 3:
        print(
            "Usage: menu_jsonc.py install|remove <dest.jsonc> [source.jsonc]",
            file=sys.stderr,
        )
        return 2
    mode, dest = argv[1], argv[2]
    source = argv[3] if len(argv) > 3 else ""
    update_menu_jsonc(dest, mode, source)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
