#!/bin/bash
# Title         : notifications.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/notifications.sh
# ----------------------------------------------------------------------------
# GitHub notifications counter with visual states
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Notifications Configuration --------------------------------------------
notifications_config=(
  position=right

  drawing=off

  icon="$BELL_DISABLED"
  icon.color="$GREY"
  icon.font="$SYMBOL_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM"
  icon.padding_left="$PADDINGS_NONE"
  icon.padding_right="$PADDINGS_NONE"

  label="--"
  label.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_XSMALL"
  label.color="$WHITE"
  label.padding_left="$PADDINGS_SMALL"
  label.padding_right="$PADDINGS_NONE"

  padding_left="$PADDINGS_SMALL"
  padding_right="$PADDINGS_MEDIUM"

  background.drawing=off

  update_freq=1800
  updates=when_shown

  script="$HOME/.config/sketchybar/plugins/notifications.sh"
  click_script="open 'https://github.com/notifications'"
)

# --- Item Creation ----------------------------------------------------------
sketchybar --add item notifications right \
  --set notifications "${notifications_config[@]}" \
  --subscribe notifications mouse.clicked mouse.entered mouse.exited control_center_update
