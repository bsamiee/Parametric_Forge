#!/bin/bash
# Title         : wifi.sh
# Author        : Bardia Samiee (adapted from reference)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/wifi.sh
# ----------------------------------------------------------------------------
# WiFi status display with live network detection
# shellcheck disable=SC1091

# --- Load Configuration Variables -------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"

# --- WiFi Item Configuration ------------------------------------------------
wifi_config=(
  script="$HOME/.config/sketchybar/plugins/wifi.sh"
  click_script="$HOME/.config/sketchybar/plugins/wifi.sh"

  label="Searching…"
  label.max_chars=10
  label.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM"
  label.color="$WHITE"
  label.padding_left="$PADDINGS_SMALL"
  label.padding_right="$PADDINGS"

  icon="􀙥"  # WiFi error icon as default
  icon.font="$SYMBOL_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM"
  icon.color="$GREY"
  icon.padding_left="$PADDINGS"
  icon.padding_right="$PADDINGS_NONE"

  padding_left="$PADDINGS_NONE"
  padding_right="$PADDINGS_NONE"

  background.drawing=off

  updates=on
  update_freq=5
  scroll_texts=off
  scroll_duration=100
)

# --- Create WiFi Item -------------------------------------------------------
sketchybar --add item wifi right \
  --set wifi "${wifi_config[@]}" \
  --subscribe wifi wifi_change mouse.entered mouse.exited mouse.clicked
