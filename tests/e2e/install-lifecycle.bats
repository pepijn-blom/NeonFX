#!/usr/bin/env bats

load ../helpers/sandbox

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

install_skip_apply() {
  "$THEME_ROOT/bin/neonfx-install" --skip-apply
}

apply_theme() {
  omarchy-theme-set "NeonFX"
}

@test "install --skip-apply wires hooks and CLIs without applying" {
  run install_skip_apply
  [ "$status" -eq 0 ]
  [ -L "$HOME/.config/omarchy/themes/neonfx" ]
  [ -e "$HOME/.config/omarchy/hooks/theme-set.d/neonfx.sh" ]
  [ -L "$HOME/.local/bin/omarchy-neonfx-apply" ]
  [ -L "$HOME/.local/bin/omarchy-neonfx-toggle" ]
  [ -L "$HOME/.local/bin/omarchy-neonfx-gui" ]
  [ ! -e "$HOME/.local/bin/neonfx-fx-control" ]
  [ ! -e "$HOME/.local/bin/omarchy-neonfx-control" ]
  [ ! -e "$HOME/.config/bat/themes/NeonFX.tmTheme" ]
  [ ! -f "$HOME/.local/state/omarchy/current/theme.name" ]
}

@test "mock theme-set installs full wiring including fx-gui" {
  install_skip_apply
  run apply_theme
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.local/state/omarchy/current/theme.name")" = "neonfx" ]
  [ -L "$HOME/.config/bat/themes/NeonFX.tmTheme" ]
  [ -L "$HOME/.local/share/mc/skins/neonfx.ini" ]
  [ -L "$HOME/.config/omarchy/theme.bash" ]
  [ -L "$HOME/.local/bin/omarchy-neonfx-gui" ]
  [ -f "$HOME/.config/fish/conf.d/omarchy-theme.fish" ]
  grep -q 'set --global EXA_COLORS' "$HOME/.config/fish/conf.d/neonfx-cli.fish"
  grep -q 'style.neon' "$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
  grep -q 'omarchy-neonfx-gui' "$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
}

@test "doctor passes after install and theme apply" {
  install_skip_apply
  apply_theme
  run "$THEME_ROOT/bin/neonfx-doctor"
  [ "$status" -eq 0 ]
}

@test "switching away removes theme-owned wiring" {
  install_skip_apply
  apply_theme
  run omarchy-theme-set "Tokyo Night"
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.config/bat/themes/NeonFX.tmTheme" ]
  [ ! -e "$HOME/.local/share/mc/skins/neonfx.ini" ]
  [ ! -e "$HOME/.config/starship.toml" ]
  [ ! -e "$HOME/.local/bin/omarchy-neonfx-apply" ]
  [ ! -e "$HOME/.local/bin/omarchy-neonfx-toggle" ]
  [ ! -e "$HOME/.local/bin/omarchy-neonfx-gui" ]
  [ ! -e "$HOME/.config/omarchy/theme.bash" ]
  omarchy-theme-set "NeonFX"
  [ -L "$HOME/.local/bin/omarchy-neonfx-gui" ]
}

@test "doctor passes after switch-away when wiring is gone" {
  install_skip_apply
  apply_theme
  omarchy-theme-set "Tokyo Night"
  run "$THEME_ROOT/bin/neonfx-doctor"
  [ "$status" -eq 0 ]
}

@test "doctor fails on stale theme links when inactive" {
  install_skip_apply
  apply_theme
  omarchy-theme-set "Tokyo Night"
  mkdir -p "$HOME/.config/bat/themes"
  ln -sfn "$THEME_ROOT/bat/NeonFX.tmTheme" \
    "$HOME/.config/bat/themes/NeonFX.tmTheme"
  run "$THEME_ROOT/bin/neonfx-doctor"
  [ "$status" -ne 0 ]
}

@test "uninstall keeps a foreign theme.bash file" {
  install_skip_apply
  mkdir -p "$HOME/.config/omarchy"
  echo "keep-me" >"$HOME/.config/omarchy/theme.bash"
  run "$THEME_ROOT/bin/neonfx-uninstall" --keep-theme-dir
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/omarchy/theme.bash" ]
  [ "$(cat "$HOME/.config/omarchy/theme.bash")" = "keep-me" ]
}

@test "uninstall removes our theme.bash symlink" {
  install_skip_apply
  apply_theme
  run "$THEME_ROOT/bin/neonfx-uninstall" --keep-theme-dir
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.config/omarchy/theme.bash" ]
}

@test "fx apply writes ghostty-shaders.conf and patched GLSL" {
  install_skip_apply
  apply_theme
  "$THEME_ROOT/bin/omarchy-neonfx-toggle" preset-full
  conf="$HOME/.local/state/omarchy/neonfx/ghostty-shaders.conf"
  [ -f "$conf" ]
  grep -q 'neon-glow.glsl' "$conf"
  grep -q 'cursor-trail.glsl' "$conf"
  grep -q 'cursor-glitch.glsl' "$conf"
  grep -q 'crt-scanlines.glsl' "$conf"
  patched="$HOME/.local/state/omarchy/neonfx/shaders/neon-glow.glsl"
  [ -f "$patched" ]
  grep -q 'const float BLOOM_STRENGTH = 2.2000;' "$patched"
  grep -q 'const float GLYPH_LIFT = 1.1500;' "$patched"
}

@test "fx apply import enables shaders from JSON" {
  install_skip_apply
  apply_theme
  cat >"$HOME/profile.json" <<'EOF'
{
  "bloom_enabled": true,
  "trail_enabled": false,
  "glitch_enabled": false,
  "crt_enabled": true,
  "bloom_strength": 1.11
}
EOF
  "$THEME_ROOT/bin/omarchy-neonfx-toggle" import "$HOME/profile.json"
  conf="$HOME/.local/state/omarchy/neonfx/ghostty-shaders.conf"
  grep -q 'neon-glow.glsl' "$conf"
  grep -q 'crt-scanlines.glsl' "$conf"
  ! grep -q 'cursor-trail.glsl' "$conf"
  patched="$HOME/.local/state/omarchy/neonfx/shaders/neon-glow.glsl"
  grep -q 'const float BLOOM_STRENGTH = 1.1100;' "$patched"
}
