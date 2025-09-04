#!/bin/bash
# Title         : calendar.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/calendar.sh
# ----------------------------------------------------------------------------
# Calendar display with date, time, and interactive seconds reveal on right-click
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"

# --- Calendar Configuration -------------------------------------------------
calendar_config=(
  position=right
  update_freq=1

  icon.drawing=off

  label.font="$TEXT_FONT:$LIGHT_WEIGHT:$SIZE_MEDIUM"
  label.color="$WHITE"
  label.padding_left="$PADDINGS_LARGE"
  label.padding_right="$PADDINGS_LARGE"

  padding_left="$PADDINGS_NONE"
  padding_right="$PADDINGS_NONE"

  background.drawing=off

  script="$HOME/.config/sketchybar/plugins/calendar.sh"
)

# --- Item Creation ----------------------------------------------------------
sketchybar --add item calendar right \
  --set calendar "${calendar_config[@]}" \
  --subscribe calendar system_woke mouse.entered mouse.exited mouse.clicked
