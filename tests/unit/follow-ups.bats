#!/usr/bin/env bats

load ../helpers/sandbox

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

@test "GUI has a single CLI name" {
  [ -x "$THEME_ROOT/bin/omarchy-neonfx-gui" ]
  [ ! -e "$THEME_ROOT/bin/omarchy-neonfx-control" ]
  [ ! -e "$THEME_ROOT/bin/neonfx-fx-control" ]
}

@test "Walker Style Neon FX opens the FX submenu" {
  grep -F '*"Neon FX"*) show_neonfx_fx_menu' "$THEME_ROOT/extensions/menu.sh"
  grep -F '*neon*) show_neonfx_fx_menu' "$THEME_ROOT/extensions/menu.sh"
}

@test "fx_config hex_to_rgb and CLI presets stay aligned with GUI labels" {
  python3 - "$THEME_ROOT" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]) / "lib"))
from fx_config import CLI_PRESETS, GUI_PRESET_LABELS, PRESETS, hex_to_rgb

r, g, b = hex_to_rgb("#00f5ff")
assert abs(r - 0.0) < 1e-6
assert abs(g - 245 / 255.0) < 1e-6
assert abs(b - 1.0) < 1e-6

assert set(GUI_PRESET_LABELS.values()) == set(CLI_PRESETS)
assert PRESETS["Full Stack"] == CLI_PRESETS["full"]
assert PRESETS["Clean (All Off)"]["bloom_enabled"] is False
assert "glyph_lift" in CLI_PRESETS["full"]
PY
}

@test "menu_jsonc install is idempotent and uses the source template" {
  src="$THEME_ROOT/extensions/omarchy-menu.jsonc"
  dest="$HOME/omarchy-menu.jsonc"
  mkdir -p "$HOME"
  printf '%s\n' '{ "style.theme": { "label": "Theme" } }' >"$dest"
  python3 "$THEME_ROOT/lib/menu_jsonc.py" install "$dest" "$src"
  python3 "$THEME_ROOT/lib/menu_jsonc.py" install "$dest" "$src"
  python3 - "$dest" <<'PY'
import json, re, sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
assert text.count('"style.neon"') == 1
assert "omarchy-neonfx-gui" in text
stripped = "\n".join(l for l in text.splitlines() if not l.lstrip().startswith("//"))
cleaned = re.sub(r",(\s*[}\]])", r"\1", stripped)
data = json.loads(cleaned)
assert "style.theme" in data
assert "style.neon" in data
assert data["style.neon"]["action"] == "omarchy-neonfx-gui"
when = data["style.neon"]["when"]
assert "neonfx" in when
assert "style.font-size" in data
assert data["style.font-size.12"]["action"] == "omarchy-neonfx-toggle font-size 12"
assert "omarchy-display-text-size" not in text
PY
  python3 "$THEME_ROOT/lib/menu_jsonc.py" remove "$dest" "$src"
  python3 - "$dest" <<'PY'
import json, re, sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
assert "style.neon" not in text
assert "style.font-size" not in text
stripped = "\n".join(l for l in text.splitlines() if not l.lstrip().startswith("//"))
cleaned = re.sub(r",(\s*[}\]])", r"\1", stripped)
data = json.loads(cleaned)
assert "style.theme" in data
PY
}

@test "cli.env.sh converts to fish exports with the same values" {
  python3 - "$THEME_ROOT" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]) / "lib"))
from cli_env import fish_from_file, parse_exports

root = Path(sys.argv[1])
values = parse_exports((root / "cli.env.sh").read_text())
fish = fish_from_file(root / "cli.env.sh")
assert set(values) == {"EXA_COLORS", "FZF_DEFAULT_OPTS", "JQ_COLORS"}
for key, value in values.items():
    assert f"set --global {key} '{value}'" in fish
fish_conf = (root / "fish.conf").read_text()
assert "EXA_COLORS=" not in fish_conf
assert "generated from cli.env.sh" in fish_conf
PY
}
