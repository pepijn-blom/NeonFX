#!/usr/bin/env bats

load ../helpers/sandbox

@test "ghostty.conf palette slots 0-15 match colors.toml" {
  python3 - "$THEME_ROOT" <<'PY'
import re, sys
from pathlib import Path

root = Path(sys.argv[1])
toml = (root / "colors.toml").read_text()
ghostty = (root / "ghostty.conf").read_text()

toml_colors = {}
for m in re.finditer(r"^color(\d+)\s*=\s*\"(#[0-9a-fA-F]{6})\"", toml, re.M):
    toml_colors[int(m.group(1))] = m.group(2).lower()

ghostty_colors = {}
for m in re.finditer(r"^palette\s*=\s*(\d+)=(#[0-9a-fA-F]{6})", ghostty, re.M):
    ghostty_colors[int(m.group(1))] = m.group(2).lower()

missing = [i for i in range(16) if i not in toml_colors or i not in ghostty_colors]
if missing:
    sys.exit(f"missing palette slots: {missing}")

mismatch = [
    f"{i}: toml={toml_colors[i]} ghostty={ghostty_colors[i]}"
    for i in range(16)
    if toml_colors[i] != ghostty_colors[i]
]
if mismatch:
    sys.exit("palette mismatch:\n" + "\n".join(mismatch))
PY
}

@test "ghostty foreground and background match colors.toml" {
  python3 - "$THEME_ROOT" <<'PY'
import re, sys
from pathlib import Path

root = Path(sys.argv[1])
toml = (root / "colors.toml").read_text()
ghostty = (root / "ghostty.conf").read_text()

def toml_val(key):
    m = re.search(rf"^{key}\s*=\s*\"(#[0-9a-fA-F]{{6}})\"", toml, re.M)
    if not m:
        sys.exit(f"missing {key} in colors.toml")
    return m.group(1).lower()

def ghostty_val(key):
    m = re.search(rf"^{key}\s*=\s*(#[0-9a-fA-F]{{6}})", ghostty, re.M)
    if not m:
        sys.exit(f"missing {key} in ghostty.conf")
    return m.group(1).lower()

pairs = [
    ("foreground", "foreground"),
    ("background", "background"),
    ("cursor", "cursor-color"),
    ("selection_background", "selection-background"),
    ("selection_foreground", "selection-foreground"),
]
bad = []
for tkey, gkey in pairs:
    if toml_val(tkey) != ghostty_val(gkey):
        bad.append(f"{tkey}/{gkey}: {toml_val(tkey)} vs {ghostty_val(gkey)}")
if bad:
    sys.exit("\n".join(bad))
PY
}
