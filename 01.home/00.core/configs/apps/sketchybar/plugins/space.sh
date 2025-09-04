#!/bin/bash
# Title         : space.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/space.sh
# ----------------------------------------------------------------------------
# Dynamic space event handler with hover effects and yabai integration
# shellcheck disable=SC1091

# --- Configuration --------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Space Functions ------------------------------------------------------
is_space_active() {
  local space_id="$1"
  local active_space
  active_space=$(yabai -m query --spaces --display | jq -r '.[] | select(.["has-focus"] == true) | .index' 2>/dev/null)
  [ "$space_id" = "$active_space" ]
}

# --- Click Handler --------------------------------------------------------
handle_click() {
  [ -z "$SID" ] && return

  if [ "$BUTTON" = "right" ]; then
    yabai -m space --destroy "$SID" 2>/dev/null || true
    sketchybar --trigger space_change --trigger windows_on_spaces 2>/dev/null || true
  else
    if ! yabai -m space --focus "$SID" 2>/dev/null; then
      echo "Warning: Failed to focus space $SID" >&2
    fi
  fi
}


# --- Event Handler -------------------------------------------------------
case "$SENDER" in
  "mouse.clicked")
    handle_click
    ;;
  "mouse.entered")
    # Use unified hover effects
    if [[ "$NAME" == "add_space" ]]; then
      handle_special_hover_effects "$NAME" "$SENDER" "add_space"
    fi
    ;;
  "mouse.exited")
    # Use unified hover effects
    if [[ "$NAME" == "add_space" ]]; then
      handle_special_hover_effects "$NAME" "$SENDER" "add_space"
    fi
    ;;
esac
