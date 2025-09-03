#!/bin/bash
# Title         : mic.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/mic.sh
# ----------------------------------------------------------------------------
# Microphone control with volume-based visual states
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Mic Configuration ------------------------------------------------------
mic_config=(
  position=right

  icon="$MIC_HIGH"
  icon.color="$PRIMARY_CYAN"
  icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM"
  icon.padding_left="$PADDINGS_MEDIUM"
  icon.padding_right="$PADDINGS_MEDIUM"

  label.drawing=off
  label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL"

  padding_left="$PADDINGS_NONE"
  padding_right="$PADDINGS_NONE"

  background.drawing=off

  script="$HOME/.config/sketchybar/plugins/mic.sh"
)

# --- Item Creation ----------------------------------------------------------
sketchybar --add item mic right \
  --set mic "${mic_config[@]}" \
  --subscribe mic mouse.clicked mouse.entered mouse.exited
