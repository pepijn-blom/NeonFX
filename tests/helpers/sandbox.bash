# Shared bats helpers. Tests must never use the real $HOME.

THEME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

setup_sandbox() {
  SANDBOX_HOME="$(mktemp -d "${TMPDIR:-/tmp}/neonfx-test.XXXXXX")"
  export HOME="$SANDBOX_HOME"
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_STATE_HOME="$HOME/.local/state"
  export XDG_CACHE_HOME="$HOME/.cache"
  export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
  export GIT_CONFIG_NOSYSTEM=1

  mkdir -p \
    "$HOME/.local/bin" \
    "$HOME/.local/share/omarchy" \
    "$HOME/.config/omarchy/themes" \
    "$HOME/.local/state/omarchy/current/theme"

  cat >"$HOME/.local/bin/omarchy-restart-terminal" <<'EOF'
#!/bin/bash
exit 0
EOF

  cat >"$HOME/.local/bin/omarchy-theme-set" <<'EOF'
#!/bin/bash
set -euo pipefail
name="${1:-}"
slug="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
mkdir -p "$HOME/.local/state/omarchy/current/theme"
printf '%s\n' "$slug" >"$HOME/.local/state/omarchy/current/theme.name"

if [[ "$slug" == "neonfx" ]]; then
  theme_dir="$HOME/.config/omarchy/themes/neonfx"
  if [[ -f "$theme_dir/fish.conf" ]]; then
    cp "$theme_dir/fish.conf" "$HOME/.local/state/omarchy/current/theme/fish.conf"
  fi
fi

hook_d="$HOME/.config/omarchy/hooks/theme-set.d/neonfx.sh"
if [[ -f $hook_d ]]; then
  bash "$hook_d" "$slug"
fi

hook_main="$HOME/.config/omarchy/hooks/theme-set"
if [[ -f $hook_main ]]; then
  bash "$hook_main"
fi
EOF

  chmod +x "$HOME/.local/bin/omarchy-restart-terminal" "$HOME/.local/bin/omarchy-theme-set"
  export PATH="$HOME/.local/bin:$PATH"
}

teardown_sandbox() {
  if [[ -n "${SANDBOX_HOME:-}" && -d $SANDBOX_HOME ]]; then
    rm -rf "$SANDBOX_HOME"
  fi
}

stub_apply() {
  cat >"$HOME/.local/bin/omarchy-neonfx-apply" <<'EOF'
#!/bin/bash
exit 0
EOF
  chmod +x "$HOME/.local/bin/omarchy-neonfx-apply"
}

failing_notify_send() {
  cat >"$HOME/.local/bin/notify-send" <<'EOF'
#!/bin/bash
exit 1
EOF
  chmod +x "$HOME/.local/bin/notify-send"
}

fx_toggle() {
  "$THEME_ROOT/bin/omarchy-neonfx-toggle" "$@"
}

load_remove_if_ours() {
  log() { :; }
  eval "$(sed -n '/^remove_if_ours()/,/^}/p' "$THEME_ROOT/bin/neonfx-uninstall")"
}

load_hex_to_rgb() {
  eval "$(sed -n '/^hex_to_rgb()/,/^}/p' "$THEME_ROOT/bin/neonfx-color-samples")"
}
