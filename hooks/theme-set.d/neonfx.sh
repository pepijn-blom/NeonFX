#!/bin/bash

# Runs via omarchy-hook theme-set when NeonFX is applied or switched away.

THEME_NAME="$1"
THEME_ROOT="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
# shellcheck source=../../lib/theme_id.sh
source "$THEME_ROOT/lib/theme_id.sh"

MENU_EXT="$HOME/.config/omarchy/extensions/menu.sh"
MENU_SRC="$THEME_ROOT/extensions/menu.sh"
STATE_DIR="$THEME_STATE_DIR"
TOGGLE_DIR="$THEME_TOGGLE_DIR"

ensure_bash_theme_source() {
  local bashrc="$HOME/.bashrc"
  local marker="# omarchy theme bash"

  [[ -f $bashrc ]] || return 0
  grep -Fq "$marker" "$bashrc" && return 0

  cat >>"$bashrc" <<'EOF'

# omarchy theme bash
[[ -f ~/.config/omarchy/theme.bash ]] && source ~/.config/omarchy/theme.bash
EOF
}

ensure_git_color_include() {
  local gitconfig="$HOME/.gitconfig"
  local marker="# ${THEME_SLUG} git colors"

  [[ -f $gitconfig ]] || touch "$gitconfig"
  grep -Fq "$marker" "$gitconfig" && return 0

  cat >>"$gitconfig" <<EOF

# ${THEME_SLUG} git colors
[include]
	path = ~/.config/git/${THEME_SLUG}.gitconfig
EOF
}

remove_git_color_include() {
  local gitconfig="$HOME/.gitconfig"

  [[ -f $gitconfig ]] || return 0
  sed -i "/# ${THEME_SLUG} git colors/,+2d" "$gitconfig"
}

ensure_delta_include() {
  local gitconfig="$HOME/.gitconfig"
  local marker="# ${THEME_SLUG} delta pager"

  command -v delta >/dev/null 2>&1 || return 0
  [[ -f $gitconfig ]] || touch "$gitconfig"
  grep -Fq "$marker" "$gitconfig" && return 0

  cat >>"$gitconfig" <<EOF

# ${THEME_SLUG} delta pager
[include]
	path = ~/.config/git/${THEME_SLUG}-delta.gitconfig
EOF
}

remove_delta_include() {
  local gitconfig="$HOME/.gitconfig"

  [[ -f $gitconfig ]] || return 0
  sed -i "/# ${THEME_SLUG} delta pager/,+2d" "$gitconfig"
}

remove_if_link() {
  local path="$1"
  local expected="$2"
  [[ -L $path ]] || return 0
  [[ $(readlink -f "$path") == "$(readlink -f "$expected")" ]] || return 0
  rm -f "$path"
}

install_cli_configs() {
  local lazygit_dir="$HOME/.config/lazygit"
  local fastfetch_dir="$HOME/.config/fastfetch"

  mkdir -p "$lazygit_dir" "$fastfetch_dir"
  ln -sfn "$THEME_ROOT/lazygit/config.yml" "$lazygit_dir/config.yml"
  ln -sfn "$THEME_ROOT/starship.toml" "$HOME/.config/starship.toml"
  ln -sfn "$THEME_ROOT/fastfetch.jsonc" "$fastfetch_dir/config.jsonc"
}

remove_cli_configs() {
  remove_if_link "$HOME/.config/lazygit/config.yml" "$THEME_ROOT/lazygit/config.yml"
  remove_if_link "$HOME/.config/starship.toml" "$THEME_ROOT/starship.toml"
  remove_if_link "$HOME/.config/fastfetch/config.jsonc" "$THEME_ROOT/fastfetch.jsonc"
}

update_omarchy_menu_jsonc() {
  local mode="$1"
  local jsonc_file="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
  python3 "$THEME_ROOT/lib/menu_jsonc.py" "$mode" "$jsonc_file" \
    "$THEME_ROOT/extensions/omarchy-menu.jsonc"
}

install_wiring() {
  local mc_ini="$HOME/.config/mc/ini"
  local mc_skin_dir="$HOME/.local/share/mc/skins"
  local bat_theme_dir="$HOME/.config/bat/themes"
  local git_config_dir="$HOME/.config/git"
  local theme_bash="$HOME/.config/omarchy/theme.bash"
  local theme_fish_dest="$HOME/.config/fish/conf.d/omarchy-theme.fish"
  local theme_fish_cli="$HOME/.config/fish/conf.d/${THEME_SLUG}-cli.fish"

  mkdir -p "$HOME/.config/omarchy/extensions" "$HOME/.local/bin" "$STATE_DIR" "$TOGGLE_DIR" "$mc_skin_dir" "$bat_theme_dir" "$git_config_dir" "$HOME/.config/fish/conf.d"
  ln -sfn "$MENU_SRC" "$MENU_EXT"
  ln -sfn "$THEME_ROOT/bin/omarchy-neonfx-apply" "$HOME/.local/bin/omarchy-neonfx-apply"
  ln -sfn "$THEME_ROOT/bin/omarchy-neonfx-toggle" "$HOME/.local/bin/omarchy-neonfx-toggle"
  ln -sfn "$THEME_ROOT/bin/omarchy-neonfx-gui" "$HOME/.local/bin/omarchy-neonfx-gui"
  ln -sfn "$THEME_ROOT/mc.ini" "$mc_skin_dir/${THEME_SLUG}.ini"
  ln -sfn "$THEME_ROOT/bat/${BAT_THEME_NAME}.tmTheme" "$bat_theme_dir/${BAT_THEME_NAME}.tmTheme"
  ln -sfn "$THEME_ROOT/bash.conf" "$theme_bash"
  ln -sfn "$THEME_ROOT/git.conf" "$git_config_dir/${THEME_SLUG}.gitconfig"
  chmod +x "$THEME_ROOT/bin/omarchy-neonfx-apply" "$THEME_ROOT/bin/omarchy-neonfx-toggle" "$THEME_ROOT/bin/omarchy-neonfx-gui"
  ensure_bash_theme_source
  ensure_git_color_include
  install_cli_configs

  if [[ -f "$THEME_ROOT/fish.conf" ]]; then
    cp "$THEME_ROOT/fish.conf" "$theme_fish_dest"
  fi
  python3 "$THEME_ROOT/lib/cli_env.py" fish "$THEME_ROOT/cli.env.sh" >"$theme_fish_cli"

  update_omarchy_menu_jsonc "install"

  if command -v delta >/dev/null 2>&1; then
    ln -sfn "$THEME_ROOT/delta.gitconfig" "$git_config_dir/${THEME_SLUG}-delta.gitconfig"
    ensure_delta_include
  fi

  if command -v bat >/dev/null 2>&1; then
    bat cache --build >/dev/null 2>&1 || true
  fi

  if [[ -f $mc_ini ]]; then
    if grep -q '^skin=' "$mc_ini"; then
      sed -i "s/^skin=.*/skin=${THEME_SLUG}/" "$mc_ini"
    else
      sed -i "/^\[Midnight-Commander\]/a skin=${THEME_SLUG}" "$mc_ini"
    fi
  fi

  if [[ ! -f "$TOGGLE_DIR/bloom" ]] && ! ls "$TOGGLE_DIR"/* >/dev/null 2>&1; then
    touch "$TOGGLE_DIR/bloom"
  fi

  omarchy-neonfx-apply
}

remove_wiring() {
  if [[ "$(readlink -f "$MENU_EXT" 2>/dev/null)" == "$(readlink -f "$MENU_SRC")" ]]; then
    rm -f "$MENU_EXT"
  fi

  update_omarchy_menu_jsonc "remove"

  if [[ -f "$HOME/.config/fish/conf.d/omarchy-theme.fish" ]] && grep -Fq "${THEME_DISPLAY}" "$HOME/.config/fish/conf.d/omarchy-theme.fish" 2>/dev/null; then
    rm -f "$HOME/.config/fish/conf.d/omarchy-theme.fish"
  fi
  rm -f "$HOME/.config/fish/conf.d/${THEME_SLUG}-cli.fish"

  remove_if_link "$HOME/.local/bin/omarchy-neonfx-apply" "$THEME_ROOT/bin/omarchy-neonfx-apply"
  remove_if_link "$HOME/.local/bin/omarchy-neonfx-toggle" "$THEME_ROOT/bin/omarchy-neonfx-toggle"
  remove_if_link "$HOME/.local/bin/omarchy-neonfx-gui" "$THEME_ROOT/bin/omarchy-neonfx-gui"
  remove_if_link "$HOME/.local/share/mc/skins/${THEME_SLUG}.ini" "$THEME_ROOT/mc.ini"
  remove_if_link "$HOME/.config/bat/themes/${BAT_THEME_NAME}.tmTheme" "$THEME_ROOT/bat/${BAT_THEME_NAME}.tmTheme"
  remove_if_link "$HOME/.config/omarchy/theme.bash" "$THEME_ROOT/bash.conf"
  remove_if_link "$HOME/.config/git/${THEME_SLUG}.gitconfig" "$THEME_ROOT/git.conf"
  remove_if_link "$HOME/.config/git/${THEME_SLUG}-delta.gitconfig" "$THEME_ROOT/delta.gitconfig"
  remove_git_color_include
  remove_delta_include
  remove_cli_configs
}

if [[ "$THEME_NAME" == "$THEME_SLUG" ]]; then
  install_wiring
else
  remove_wiring
fi
