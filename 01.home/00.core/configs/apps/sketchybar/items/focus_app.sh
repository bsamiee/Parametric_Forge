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

# --- Front App Configuration ------------------------------------------------
focus_app_config=(
  position=left

  # Match active space indicator (cyan background, black text, thin light border)
  background.drawing=on
  background.color="$PRIMARY_CYAN"
  background.border_color="$LIGHT_WHITE"
  background.border_width="$BORDER_THIN"
  background.height="$HEIGHT_ITEM"
  background.corner_radius="$RADIUS_LARGE"

  icon.drawing=on
  icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM"
  icon.color="$BLACK"  # default icon color for grid
  icon.padding_left="$PADDINGS_MEDIUM"
  icon.padding_right="$PADDINGS_MEDIUM"

  label.color="$BLACK"
  label.font="$TEXT_FONT:$LIGHT_WEIGHT:$SIZE_MEDIUM"
  label.padding_left="$PADDINGS_SMALL"
  label.padding_right="$PADDINGS_MEDIUM"

  padding_left="$PADDINGS_NONE"
  padding_right="$PADDINGS_MEDIUM"

  script="$HOME/.config/sketchybar/plugins/window_state.sh"

  display=active
)

# --- Item Creation ----------------------------------------------------------
sketchybar --add item focus_app left \
  --set focus_app "${focus_app_config[@]}" \
  --subscribe focus_app pf_window_focus front_app_switched mouse.clicked
