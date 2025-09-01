#!/bin/bash
# Title         : space.sh
# Author        : Bardia Samiee (adapted from FelixKratz)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/space.sh
# ----------------------------------------------------------------------------
# Individual space interaction and animation handling
# shellcheck disable=SC1091

# --- Space state is now managed centrally by yabai.sh ---
# This script only handles mouse interactions

# --- Mouse Event Handler ----------------------------------------------------
mouse_clicked() {
  if [ "$BUTTON" = "right" ]; then
    yabai -m space --destroy "$SID"
    sketchybar --trigger space_change --trigger windows_on_spaces
  else
    yabai -m space --focus "$SID" 2>/dev/null
  fi
}

# --- Event Dispatcher -------------------------------------------------------
case "$SENDER" in
"mouse.clicked")
  mouse_clicked
  ;;
"mouse.entered"|"mouse.exited")
  # Handle tooltip events
  "$HOME/.config/sketchybar/plugins/tooltip.sh"
  ;;
esac
