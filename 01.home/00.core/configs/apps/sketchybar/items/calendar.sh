#!/bin/bash
# Title         : calendar.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/calendar.sh
# ----------------------------------------------------------------------------
# Simple calendar item matching screenshot format: "Tue Sep 2 03:03"
# shellcheck disable=SC1091

# --- Load Configuration Variables -------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"

# --- Calendar Item Configuration --------------------------------------------
calendar_config=(
  position=right
  update_freq=60

  icon.drawing=off

  label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_LARGE"
  label.color="$WHITE"
  label.padding_left="$PADDINGS_LARGE"
  label.padding_right="$PADDINGS_LARGE"

  padding_left="$PADDINGS_NONE"
  padding_right="$PADDINGS_NONE"

  background.drawing=off

  script="$HOME/.config/sketchybar/plugins/calendar.sh"
  click_script="open -b com.apple.notificationcenterui"
)

# --- Create Calendar Item ---------------------------------------------------
sketchybar --add item calendar right \
  --set calendar "${calendar_config[@]}" \
  --subscribe calendar system_woke mouse.entered mouse.exited mouse.clicked
