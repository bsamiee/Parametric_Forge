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

  icon.drawing=on
  icon.font="$TEXT_FONT:$LIGHT_WEIGHT:$SIZE_MEDIUM"
  icon.color="$WHITE"
  icon.padding_left="$PADDINGS_LARGE"
  # Slightly increase the gap between the last dash and time
  icon.padding_right="$PADDINGS_MEDIUM"

  label.font="$TEXT_FONT:$LIGHT_WEIGHT:$SIZE_MEDIUM"
  label.color="$PRIMARY_CYAN"
  # Add a small left padding to time for clearer separation
  label.padding_left="$PADDINGS_SMALL"
  # Keep right padding minimal so seconds can sit flush next to time
  label.padding_right="$PADDINGS_SMALL"

  padding_left="$PADDINGS_NONE"
  padding_right="$PADDINGS_NONE"

  background.drawing=off

  script="$HOME/.config/sketchybar/plugins/calendar.sh"
)

# --- Main Calendar Item Creation --------------------------------------------
sketchybar --add item calendar right \
  --set calendar "${calendar_config[@]}" \
  --subscribe calendar system_woke mouse.entered mouse.exited mouse.clicked

# --- Seconds Suffix Item Configuration --------------------------------------
calendar_secs_config=(
  position=right
  drawing=off

  icon.drawing=off

  label.font="$TEXT_FONT:$LIGHT_WEIGHT:$SIZE_MEDIUM"
  label.color="$RED"
  label.padding_left="$PADDINGS_NONE"
  label.padding_right="$PADDINGS_LARGE"

  padding_left="$PADDINGS_NONE"
  padding_right="$PADDINGS_NONE"

  background.drawing=off
)

sketchybar --add item calendar_secs right \
  --set calendar_secs "${calendar_secs_config[@]}" \
  script="$HOME/.config/sketchybar/plugins/calendar.sh" \
  --subscribe calendar_secs system_woke mouse.entered mouse.exited mouse.clicked

# --- Calendar Group Configuration -------------------------------------------
sketchybar --move calendar_secs before calendar

sketchybar --add bracket calendar_group calendar_secs calendar \
  --set calendar_group \
    background.drawing=off \
    background.color="$FAINT_GREY" \
    background.corner_radius="$RADIUS_LARGE" \
    background.height="$HEIGHT_ITEM" \
    background.border_width="$BORDER_NONE"
