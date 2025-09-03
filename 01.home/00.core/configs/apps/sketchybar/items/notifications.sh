#!/bin/bash
# Title         : notifications.sh
# Author        : Bardia Samiee (adapted from reference)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/notifications.sh
# ----------------------------------------------------------------------------
# GitHub notifications counter with visual states
# shellcheck disable=SC1091

# --- Load Configuration Variables -------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Notifications Item Configuration ---------------------------------------
notifications_config=(
  position=right

  # Hidden by default (shown via more-menu toggle)
  drawing=off

  # Visual styling
  icon="$BELL_DISABLED"
  icon.color="$GREY"
  icon.font="$SYMBOL_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM"
  icon.padding_left="$PADDINGS_NONE"
  icon.padding_right="$PADDINGS_NONE"

  # Label configuration
  label="--"
  label.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_XSMALL"
  label.color="$WHITE"
  label.padding_left="$PADDINGS_SMALL"
  label.padding_right="$PADDINGS_NONE"

  # Positioning and spacing
  padding_left="$PADDINGS_SMALL"
  padding_right="$PADDINGS_MEDIUM"

  # No background drawing
  background.drawing=off

  # Update frequency: 30 minutes
  update_freq=1800
  updates=when_shown

  # Scripts and functionality
  script="$HOME/.config/sketchybar/plugins/notifications.sh"
  click_script="open 'https://github.com/notifications'"
)

# --- Create Notifications Item ----------------------------------------------
sketchybar --add item notifications right \
  --set notifications "${notifications_config[@]}" \
  --subscribe notifications mouse.clicked mouse.entered mouse.exited more_menu_update
