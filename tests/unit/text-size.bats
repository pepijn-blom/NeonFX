#!/usr/bin/env bats

load ../helpers/sandbox

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

@test "clamp_font_size stays within Ghostty 6-18 pt range" {
  python3 - "$THEME_ROOT" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]) / "lib"))
from text_size import FONT_SIZE_DEFAULT, FONT_SIZE_MAX, FONT_SIZE_MIN, clamp_font_size

assert FONT_SIZE_MIN == 6
assert FONT_SIZE_MAX == 18
assert FONT_SIZE_DEFAULT == 9
assert clamp_font_size(9) == 9
assert clamp_font_size(6) == 6
assert clamp_font_size(18) == 18
assert clamp_font_size(5) == 6
assert clamp_font_size(21) == 18
assert clamp_font_size(11.6) == 12
assert clamp_font_size("14") == 14
assert clamp_font_size("nope") == 9
assert clamp_font_size(None) == 9
PY
}

@test "read_ghostty_font_size parses font-size and ignores other keys" {
  python3 - "$THEME_ROOT" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]) / "lib"))
from text_size import current_font_size, read_ghostty_font_size

missing = Path("/tmp/does-not-exist-neonfx-ghostty.conf")
assert read_ghostty_font_size(missing) is None
assert current_font_size(missing) == 9

cfg = Path.home() / "ghostty.conf"
cfg.write_text(
    "font-family = \"JetBrainsMono Nerd Font\"\nfont-size = 11\nwindow-padding-x = 14\n",
    encoding="utf-8",
)
assert read_ghostty_font_size(cfg) == 11
assert current_font_size(cfg) == 11

empty = Path.home() / "empty.conf"
empty.write_text("window-theme = ghostty\n", encoding="utf-8")
assert read_ghostty_font_size(empty) is None
assert current_font_size(empty) == 9
PY
}

@test "apply_font_size writes only Ghostty config and reloads Ghostty" {
  python3 - "$THEME_ROOT" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]) / "lib"))
from text_size import apply_font_size

cfg = Path.home() / "ghostty.conf"
cfg.write_text(
    "# Font\nfont-family = \"JetBrainsMono Nerd Font\"\nfont-size = 9\n",
    encoding="utf-8",
)
reloads = []

def reloader():
    reloads.append("ghostty")

result = apply_font_size(14, config_path=cfg, reloader=reloader)
assert result.returncode == 0
text = cfg.read_text(encoding="utf-8")
assert "font-size = 14" in text
assert "font-family = \"JetBrainsMono Nerd Font\"" in text
assert text.count("font-size") == 1
assert reloads == ["ghostty"]

apply_font_size(3, config_path=cfg, reloader=reloader)
assert "font-size = 6" in cfg.read_text(encoding="utf-8")
PY
}

@test "apply_font_size never calls omarchy-display-text-size" {
  python3 - "$THEME_ROOT" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]) / "lib"))
import text_size

src = Path(text_size.__file__).read_text(encoding="utf-8")
assert "omarchy-display-text-size" not in src
assert "shell.toml" not in src
PY
}

@test "toggle font-size writes Ghostty config and skips shader apply" {
  stub_apply
  mkdir -p "$HOME/.config/ghostty"
  printf '%s\n' 'font-family = "JetBrainsMono Nerd Font"' 'font-size = 9' >"$HOME/.config/ghostty/config"
  run fx_toggle font-size 12
  [ "$status" -eq 0 ]
  grep -q '^font-size = 12$' "$HOME/.config/ghostty/config"
  grep -q 'JetBrainsMono' "$HOME/.config/ghostty/config"
}

@test "Live Sliders GUI exposes a Ghostty-only font size slider" {
  grep -F 'Ghostty' "$THEME_ROOT/bin/omarchy-neonfx-gui"
  grep -F 'on_font_size_change' "$THEME_ROOT/bin/omarchy-neonfx-gui"
  grep -F 'apply_font_size' "$THEME_ROOT/bin/omarchy-neonfx-gui"
  ! grep -F 'omarchy-display-text-size' "$THEME_ROOT/bin/omarchy-neonfx-gui"
  ! grep -F 'shell, GTK, and terminals' "$THEME_ROOT/bin/omarchy-neonfx-gui"
}
