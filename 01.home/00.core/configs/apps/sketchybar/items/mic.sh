#!/bin/bash
# Title         : mic.sh
# Author        : Bardia Samiee (adapted from reference)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/mic.sh
# ----------------------------------------------------------------------------
# Microphone control with volume-based visual states
# shellcheck disable=SC1091

# --- Load Configuration Variables -------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Mic Item Configuration -------------------------------------------------
mic_config=(
  position=right

  # Visual styling
  icon="$MIC_HIGH"
  icon.color="$PRIMARY_CYAN"
  icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM"
  icon.padding_left="$PADDINGS"
  icon.padding_right="$PADDINGS"

  # Label hidden by default (used for volume storage)
  label.drawing=off
  label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL"

  # Positioning and spacing
  padding_left="$PADDINGS_NONE"
  padding_right="$PADDINGS_NONE"

  # No background drawing
  background.drawing=off

  # Scripts and functionality
  script="$HOME/.config/sketchybar/plugins/mic.sh"
)

# --- Create Mic Item --------------------------------------------------------
sketchybar --add item mic right \
  --set mic "${mic_config[@]}" \
  --subscribe mic mouse.clicked mouse.entered mouse.exited
