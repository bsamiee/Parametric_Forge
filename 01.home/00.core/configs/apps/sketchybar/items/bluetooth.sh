#!/bin/bash
# Title         : bluetooth.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/bluetooth.sh
# ----------------------------------------------------------------------------
# Bluetooth status monitor with device management, battery levels, and Control Center integration
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Bluetooth Item Configuration -------------------------------------------
bluetooth_config=(
  script="$HOME/.config/sketchybar/plugins/bluetooth.sh"
  click_script="$HOME/.config/sketchybar/plugins/bluetooth.sh"

  label.drawing=off

  icon="$BLUETOOTH_OFF"  # Default to off state
  icon.font="$SYMBOL_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM"
  icon.color="$GREY"
  icon.padding_left="$PADDINGS_MEDIUM"
  icon.padding_right="$PADDINGS_NONE"

  padding_left="$PADDINGS_NONE"
  padding_right="$PADDINGS_NONE"

  background.drawing=off

  updates=on
  update_freq=10
)

# --- Create Bluetooth Item --------------------------------------------------
sketchybar --add item bluetooth right \
  --set bluetooth "${bluetooth_config[@]}" \
  --subscribe bluetooth bluetooth_change mouse.entered mouse.exited mouse.clicked