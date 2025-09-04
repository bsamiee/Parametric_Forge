#!/bin/bash
# Title         : focus_app.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/focus_app.sh
# ----------------------------------------------------------------------------
# Enhanced front app display with app icons and visual feedback
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Front App Configuration ------------------------------------------------
front_app_config=(
  position=left

  background.color="$TRANSPARENT"
  background.border_color="$LIGHT_WHITE"
  background.border_width="$BORDER_THIN"
  background.height="$HEIGHT_ITEM"
  background.corner_radius="$RADIUS_LARGE"
  background.padding_left="$PADDINGS_MEDIUM"
  background.padding_right="$PADDINGS_MEDIUM"
  background.drawing=off

  icon.drawing=on
  icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM"
  icon.color="$ORANGE"
  icon.padding_left="$PADDINGS_MEDIUM"
  icon.padding_right="$PADDINGS_MEDIUM"

  label.color="$WHITE"
  label.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM"
  label.padding_left="$PADDINGS_SMALL"
  label.padding_right="$PADDINGS_LARGE"

  padding_left="$PADDINGS_SMALL"
  padding_right="$PADDINGS_MEDIUM"

  script="$HOME/.config/sketchybar/plugins/window_state.sh"

  associated_display=active
)

# --- Item Creation ----------------------------------------------------------
sketchybar --add item front_app left \
  --set front_app "${front_app_config[@]}" \
  --subscribe front_app window_focus mouse.entered mouse.exited mouse.exited.global mouse.clicked
