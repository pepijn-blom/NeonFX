# Shared NeonFX identifiers. Sourced by install, doctor, uninstall, and the theme hook.

THEME_SLUG="neonfx"
THEME_DISPLAY="NeonFX"
THEME_REPO="pepijn-blom/NeonFX"
THEME_GIT_URL="https://github.com/pepijn-blom/NeonFX.git"

BAT_THEME_NAME="NeonFX"

THEME_STATE_DIR="${HOME}/.local/state/omarchy/${THEME_SLUG}"
THEME_TOGGLE_DIR="${HOME}/.local/state/omarchy/toggles/${THEME_SLUG}"

THEME_CLI_SCRIPTS=(
  neonfx-install
  neonfx-doctor
  neonfx-uninstall
  omarchy-neonfx-apply
  omarchy-neonfx-toggle
  omarchy-neonfx-gui
)
