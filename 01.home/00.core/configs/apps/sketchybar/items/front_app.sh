#!/bin/bash
# Title         : front_app.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/front_app.sh
# ----------------------------------------------------------------------------
# Enhanced front app display with app icons and visual feedback
# shellcheck disable=SC1091

# --- Load Configuration Variables -------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"

# --- Front App Item Configuration -------------------------------------------
front_app_config=(
  position=left

  # Visual styling with Dracula theme
  background.color="$FAINT_DARK_GREY"
  background.height="$HEIGHT_ITEM"
  background.corner_radius="$RADIUS_LARGE"
  background.drawing=on

  # Icon disabled for text-only display
  icon.drawing=off

  # Label configuration
  label.color="$WHITE"
  label.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_SMALL"
  label.padding_left="$PADDINGS_SMALL"
  label.padding_right="$PADDINGS"

  # Positioning and spacing
  padding_left="$PADDINGS_SMALL"
  padding_right="$PADDINGS"

  # Scripts and functionality
  script="$HOME/.config/sketchybar/plugins/front_app.sh"
  click_script="yabai -m window --toggle float"

  # Display association
  associated_display=active
)

# --- Create Front App Item --------------------------------------------------
sketchybar --add item front_app left \
  --set front_app "${front_app_config[@]}" \
  --subscribe front_app system_woke front_app_switched window_focus mouse.entered mouse.exited mouse.clicked
