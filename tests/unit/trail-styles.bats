#!/usr/bin/env bats

load ../helpers/sandbox

setup() {
  setup_sandbox
  stub_apply
  mkdir -p "$HOME/.local/state/omarchy/toggles/neonfx"
  mkdir -p "$HOME/.local/state/omarchy/neonfx"
}

teardown() {
  teardown_sandbox
}

@test "default trail_style is blaze-spear and catalog lists every style file" {
  python3 - "$THEME_ROOT" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
sys.path.insert(0, str(root / "lib"))
from fx_config import DEFAULT_CONFIG, DEFAULT_TRAIL_STYLE, TRAIL_STYLES, resolve_trail_style

assert DEFAULT_TRAIL_STYLE == "blaze-spear"
assert DEFAULT_CONFIG["trail_style"] == "blaze-spear"
assert TRAIL_STYLES[0][0] == "blaze-spear"
assert TRAIL_STYLES[0][1] == "Blaze Spear"
ids = [sid for sid, _ in TRAIL_STYLES]
assert "comet-smear" in ids
assert "hex-smear" in ids
assert resolve_trail_style("hex-smear") == "hex-smear"
assert resolve_trail_style("not-a-style") == "blaze-spear"
assert resolve_trail_style(None) == "blaze-spear"
for sid, _label in TRAIL_STYLES:
    path = root / "shaders" / "trails" / f"{sid}.glsl"
    assert path.is_file(), f"missing {path}"
PY
}

@test "set trail_style hex-smear persists in fx-config.json" {
  run fx_toggle set trail_style hex-smear
  [ "$status" -eq 0 ]
  grep -q '"trail_style": "hex-smear"' "$HOME/.local/state/omarchy/neonfx/fx-config.json"
}

@test "trail-style alias writes the selected style" {
  run fx_toggle trail-style frost-blaze
  [ "$status" -eq 0 ]
  grep -q '"trail_style": "frost-blaze"' "$HOME/.local/state/omarchy/neonfx/fx-config.json"
}

@test "patch_shader_sources writes blaze-spear to cursor-trail.glsl and patches duration" {
  python3 - "$THEME_ROOT" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
sys.path.insert(0, str(root / "lib"))
from fx_config import DEFAULT_CONFIG, patch_shader_sources

cfg = dict(DEFAULT_CONFIG)
cfg["trail_style"] = "blaze-spear"
cfg["trail_duration"] = 0.42
cfg["trail_color"] = "#00f5ff"
patched = patch_shader_sources(str(root), cfg)
assert "cursor-trail.glsl" in patched
src = patched["cursor-trail.glsl"]
assert "Blaze Spear" in src or "centerCP" in src
assert "const float DURATION = 0.4200;" in src
assert "TRAIL_BLOOM_ENABLED" not in src
PY
}

@test "unknown trail_style falls back to blaze-spear on apply" {
  python3 - "$THEME_ROOT" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
sys.path.insert(0, str(root / "lib"))
from fx_config import DEFAULT_CONFIG, patch_shader_sources

cfg = dict(DEFAULT_CONFIG)
cfg["trail_style"] = "does-not-exist"
patched = patch_shader_sources(str(root), cfg)
assert "cursor-trail.glsl" in patched
src = patched["cursor-trail.glsl"]
assert "vec2 v3 = centerCP;" in src
PY
}

@test "cursor-glitch passes through original pixels when Ghostty is unfocused" {
  python3 - "$THEME_ROOT" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
sys.path.insert(0, str(root / "lib"))
from fx_config import DEFAULT_CONFIG, patch_shader_sources

source = (root / "shaders" / "cursor-glitch.glsl").read_text()
assert "if (iFocus == 0)" in source, "unfocused frames must skip the tear"
assert "fragColor = original;" in source

patched = patch_shader_sources(str(root), dict(DEFAULT_CONFIG))
glitch = patched["cursor-glitch.glsl"]
assert "if (iFocus == 0)" in glitch
assert "TEAR_STRENGTH" in glitch
PY
}

@test "compiled trails pass through original pixels when Ghostty is unfocused" {
  python3 - "$THEME_ROOT" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
sys.path.insert(0, str(root / "lib"))
from fx_config import DEFAULT_CONFIG, TRAIL_STYLES, patch_shader_sources

for style, _label in TRAIL_STYLES:
    cfg = dict(DEFAULT_CONFIG)
    cfg["trail_style"] = style
    src = patch_shader_sources(str(root), cfg)["cursor-trail.glsl"]
    assert "if (iFocus == 0)" in src, f"{style} must skip FX on unfocused frames"
PY
}

@test "comet-smear still receives bloom and smear patches" {
  python3 - "$THEME_ROOT" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
sys.path.insert(0, str(root / "lib"))
from fx_config import DEFAULT_CONFIG, patch_shader_sources

cfg = dict(DEFAULT_CONFIG)
cfg["trail_style"] = "comet-smear"
cfg["trail_bloom_enabled"] = False
cfg["trail_size"] = 0.55
patched = patch_shader_sources(str(root), cfg)
src = patched["cursor-trail.glsl"]
assert "const float TRAIL_BLOOM_ENABLED = 0.0;" in src
assert "const float TRAIL_SIZE = 0.5500;" in src
PY
}
