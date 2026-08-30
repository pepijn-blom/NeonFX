#!/bin/bash

# NeonFX — Omarchy menu extension (Style → Neon FX)
# Duplicates upstream show_style_menu — diff when Omarchy updates.

neonfx_active() {
  ([[ -f "$HOME/.local/state/omarchy/current/theme.name" ]] &&
    [[ $(cat "$HOME/.local/state/omarchy/current/theme.name") == "neonfx" ]]) ||
  ([[ -f "$HOME/.config/omarchy/current/theme.name" ]] &&
    [[ $(cat "$HOME/.config/omarchy/current/theme.name") == "neonfx" ]])
}

neonfx_fx_enabled() {
  [[ -f "$HOME/.local/state/omarchy/toggles/neonfx/$1" ]]
}

neonfx_fx_label() {
  local name="$1"
  local key="$2"
  if neonfx_fx_enabled "$key"; then
    echo "$name  ON"
  else
    echo "$name  OFF"
  fi
}

show_neonfx_fx_menu() {
  if ! neonfx_active; then
    notify-send -u low "Neon FX" "Switch to NeonFX theme first."
    back_to show_style_menu
    return
  fi

  local intensity
  intensity=$(cat "$HOME/.local/state/omarchy/toggles/neonfx/bloom-intensity" 2>/dev/null || echo "medium")

  local choice options
  options="$(cat <<EOF
⚡  Live Sliders & Controls
󰐊  Preset: Full stack
󰑊  Preset: Terminal only
󰌵  Preset: Subtle glow
󰓛  Preset: Off
󰌵  Glow: Subtle $([[ "$intensity" == "subtle" ]] && echo "✓")
󰌵  Glow: Medium $([[ "$intensity" == "medium" ]] && echo "✓")
󰌵  Glow: Intense $([[ "$intensity" == "intense" ]] && echo "✓")
$(neonfx_fx_label "Text bloom" bloom)
$(neonfx_fx_label "Cursor trail" cursor-trail)
$(neonfx_fx_label "Cursor glitch" cursor-glitch)
$(neonfx_fx_label "Terminal CRT" terminal-crt)
←  Back
EOF
)"

  choice=$(menu "Neon FX" "$options")

  if [[ $choice == "CNCLD" || -z $choice || $choice == *Back* ]]; then
    back_to show_style_menu
    return
  fi

  case $choice in
  *"Live Sliders"*) omarchy-neonfx-gui & ;;
  *"Full stack"*) omarchy-neonfx-toggle preset-full ;;
  *"Terminal only"*) omarchy-neonfx-toggle preset-terminal ;;

  *"Subtle glow"*) omarchy-neonfx-toggle preset-subtle ;;
  *"Preset: Off"*) omarchy-neonfx-toggle preset-off ;;
  *"Glow: Subtle"*) omarchy-neonfx-toggle bloom-intensity subtle ;;
  *"Glow: Medium"*) omarchy-neonfx-toggle bloom-intensity medium ;;
  *"Glow: Intense"*) omarchy-neonfx-toggle bloom-intensity intense ;;
  *"Text bloom"*) omarchy-neonfx-toggle bloom ;;
  *"Cursor trail"*) omarchy-neonfx-toggle cursor-trail ;;
  *"Cursor glitch"*) omarchy-neonfx-toggle cursor-glitch ;;
  *"Terminal CRT"*) omarchy-neonfx-toggle terminal-crt ;;
  *) back_to show_style_menu; return ;;
  esac

  show_neonfx_fx_menu
}


show_style_menu() {
  local style_options="󰸌  Theme\n󰟵  Unlock\n  Font\n  Background\n  Hyprland\n󱄄  Screensaver\n  About"

  if neonfx_active; then
    style_options="⚡  Neon FX\n$style_options"
  fi

  case $(menu "Style" "$style_options") in
  *"Neon FX"*) show_neonfx_fx_menu ;;
  *Theme*) show_theme_menu ;;
  *Unlock*) omarchy-launch-walker -m menus:omarchyunlocks --width 800 --minheight 400 ;;
  *Font*) show_font_menu ;;
  *Background*) show_background_menu ;;
  *Hyprland*) open_in_editor ~/.config/hypr/looknfeel.conf ;;
  *Screensaver*) show_screensaver_menu ;;
  *About*) show_about_menu ;;
  *) show_main_menu ;;
  esac
}

go_to_menu() {
  case "${1,,}" in
  *apps*) walker -p "Launch…" ;;
  *learn*) show_learn_menu ;;
  *trigger*) show_trigger_menu ;;
  *toggle*) show_toggle_menu ;;
  *hardware*) show_hardware_menu ;;
  *share*) show_share_menu ;;
  *reminder-set*) show_custom_reminder_input ;;
  *reminder*) show_reminder_menu ;;
  *background*) show_background_menu ;;
  *capture*) show_capture_menu ;;
  *style*) show_style_menu ;;
  *theme*) show_theme_menu ;;
  *neon*) show_neonfx_fx_menu ;;
  *screenrecord*) show_screenrecord_menu ;;
  *setup*) show_setup_menu ;;
  *power*) show_setup_power_menu ;;
  *install*) show_install_menu ;;
  *remove*) show_remove_menu ;;
  *update*) show_update_menu ;;
  *about*) show_about ;;
  *system*) show_system_menu ;;
  esac
}
