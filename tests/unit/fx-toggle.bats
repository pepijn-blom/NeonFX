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

@test "fx_set on creates a toggle file" {
  run fx_toggle bloom on
  [ "$status" -eq 0 ]
  [ -f "$HOME/.local/state/omarchy/toggles/neonfx/bloom" ]
}

@test "fx_set off removes a toggle file" {
  touch "$HOME/.local/state/omarchy/toggles/neonfx/bloom"
  run fx_toggle bloom off
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.local/state/omarchy/toggles/neonfx/bloom" ]
}

@test "fx_set toggle flips a toggle file" {
  run fx_toggle cursor-trail
  [ "$status" -eq 0 ]
  [ -f "$HOME/.local/state/omarchy/toggles/neonfx/cursor-trail" ]
  run fx_toggle cursor-trail
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.local/state/omarchy/toggles/neonfx/cursor-trail" ]
}

@test "preset-full writes all effect toggles and JSON flags" {
  run fx_toggle preset-full
  [ "$status" -eq 0 ]
  [ -f "$HOME/.local/state/omarchy/toggles/neonfx/bloom" ]
  [ -f "$HOME/.local/state/omarchy/toggles/neonfx/cursor-trail" ]
  [ -f "$HOME/.local/state/omarchy/toggles/neonfx/cursor-glitch" ]
  [ -f "$HOME/.local/state/omarchy/toggles/neonfx/terminal-crt" ]
  grep -q '"bloom_enabled": true' "$HOME/.local/state/omarchy/neonfx/fx-config.json"
  grep -q '"trail_enabled": true' "$HOME/.local/state/omarchy/neonfx/fx-config.json"
  grep -q '"glitch_enabled": true' "$HOME/.local/state/omarchy/neonfx/fx-config.json"
  grep -q '"crt_enabled": true' "$HOME/.local/state/omarchy/neonfx/fx-config.json"
}

@test "preset-off clears toggles and JSON enabled flags" {
  fx_toggle preset-full
  run fx_toggle preset-off
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.local/state/omarchy/toggles/neonfx/bloom" ]
  [ ! -f "$HOME/.local/state/omarchy/toggles/neonfx/cursor-trail" ]
  grep -q '"bloom_enabled": false' "$HOME/.local/state/omarchy/neonfx/fx-config.json"
  grep -q '"trail_enabled": false' "$HOME/.local/state/omarchy/neonfx/fx-config.json"
}

@test "preset-subtle enables only bloom" {
  run fx_toggle preset-subtle
  [ "$status" -eq 0 ]
  [ -f "$HOME/.local/state/omarchy/toggles/neonfx/bloom" ]
  [ ! -f "$HOME/.local/state/omarchy/toggles/neonfx/cursor-trail" ]
  [ ! -f "$HOME/.local/state/omarchy/toggles/neonfx/cursor-glitch" ]
  [ ! -f "$HOME/.local/state/omarchy/toggles/neonfx/terminal-crt" ]
}

@test "import syncs toggle files from JSON enabled flags" {
  cat >"$HOME/import.json" <<'EOF'
{
  "bloom_enabled": true,
  "trail_enabled": true,
  "glitch_enabled": false,
  "crt_enabled": false
}
EOF
  run fx_toggle import "$HOME/import.json"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.local/state/omarchy/toggles/neonfx/bloom" ]
  [ -f "$HOME/.local/state/omarchy/toggles/neonfx/cursor-trail" ]
  [ ! -f "$HOME/.local/state/omarchy/toggles/neonfx/cursor-glitch" ]
  [ ! -f "$HOME/.local/state/omarchy/toggles/neonfx/terminal-crt" ]
}

@test "set bloom_enabled true creates the bloom toggle file" {
  run fx_toggle set bloom_enabled true
  [ "$status" -eq 0 ]
  [ -f "$HOME/.local/state/omarchy/toggles/neonfx/bloom" ]
}

@test "set trail_enabled false removes the cursor-trail toggle file" {
  touch "$HOME/.local/state/omarchy/toggles/neonfx/cursor-trail"
  run fx_toggle set trail_enabled false
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.local/state/omarchy/toggles/neonfx/cursor-trail" ]
}

@test "notify-send failure does not abort a successful toggle" {
  failing_notify_send
  run fx_toggle preset-off
  [ "$status" -eq 0 ]
}
