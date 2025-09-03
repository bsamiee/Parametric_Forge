#!/bin/bash
# Title         : volume.sh
# Author        : Bardia Samiee (adapted from reference)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/volume.sh
# ----------------------------------------------------------------------------
# Consolidated volume plugin with interactive slider and dynamic icon
# shellcheck disable=SC1091
# shellcheck disable=SC2153 # PERCENTAGE is provided by SketchyBar slider events

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Volume Configuration ---------------------------------------------------
SLIDER_WIDTH=100

# --- Volume Status Update ---------------------------------------------------
update_volume_display() {
  local volume_level="$INFO"
  local icon

  # Select icon based on volume level
  case "$volume_level" in
    [6-9][0-9]|100)
      icon="$VOLUME_100"  # 60-100%
      ;;
    [3-5][0-9])
      icon="$VOLUME_66"   # 30-59%
      ;;
    [1-2][0-9])
      icon="$VOLUME_33"   # 10-29%
      ;;
    [1-9])
      icon="$VOLUME_10"   # 1-9%
      ;;
    0)
      icon="$VOLUME_0"    # 0%
      ;;
    *)
      icon="$VOLUME_100"  # Default to max
      ;;
  esac

  # Update volume icon
  apply_instant_change "volume_icon" icon="$icon"

  # Update and show slider
  apply_instant_change "volume" slider.percentage="$volume_level"
  apply_smooth_animation "volume" 30 slider.width="$SLIDER_WIDTH"

  # Auto-hide slider after delay
  (
    sleep 2
    # Check if volume changed while sleeping
    local final_percentage
    final_percentage=$(get_item_state "volume" "slider.percentage")
    if [[ "$final_percentage" == "$volume_level" ]]; then
      apply_smooth_animation "volume" 30 slider.width=0
    fi
  ) &
}

# --- Slider Interaction -----------------------------------------------------
handle_slider_click() {
  # Set volume based on slider percentage
  local percentage="$PERCENTAGE"
  osascript -e "set volume output volume $percentage" 2>/dev/null
}

handle_slider_hover() {
  case "$1" in
    "entered")
      apply_instant_change "volume" slider.knob.drawing=on
      ;;
    "exited")
      apply_instant_change "volume" slider.knob.drawing=off
      ;;
  esac
}

# --- Volume Icon Interaction ------------------------------------------------
handle_icon_click() {
  if [[ "$BUTTON" == "left" ]]; then
    # Left click: Toggle slider visibility
    local current_width
    current_width=$(get_item_state "volume" "slider.width")

    if [[ "$current_width" == "0" ]]; then
      apply_smooth_animation "volume" 30 slider.width="$SLIDER_WIDTH"
    else
      apply_smooth_animation "volume" 30 slider.width=0
    fi
  else
    # Right click: Open Sound Control Center
    if command -v menubar >/dev/null 2>&1; then
      menubar -s "Control Center,Sound"
    else
      # Fallback: Open Sound preferences
      open "x-apple.systempreferences:com.apple.preference.sound"
    fi
  fi
}

# --- Main Event Handler -----------------------------------------------------
case "$NAME" in
  "volume")
    # Handle slider events
    case "$SENDER" in
      "volume_change")
        update_volume_display
        ;;
      "mouse.clicked")
        handle_slider_click
        ;;
      "mouse.entered")
        handle_slider_hover "entered"
        ;;
      "mouse.exited")
        handle_slider_hover "exited"
        ;;
    esac
    ;;
  "volume_icon")
    # Handle icon events
    case "$SENDER" in
      "mouse.clicked")
        handle_mouse_event "$NAME" "$SENDER"
        handle_icon_click
        ;;
      "mouse.entered"|"mouse.exited")
        handle_mouse_event "$NAME" "$SENDER"
        ;;
    esac
    ;;
esac
