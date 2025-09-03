#!/bin/bash
# Title         : packages.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/packages.sh
# ----------------------------------------------------------------------------
# System-wide package counter across all package managers
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Packages Configuration -------------------------------------------------
packages_config=(
  position=right

  drawing=off
  icon="$PACKAGE"
  icon.color="$PINK"
  icon.font="$SYMBOL_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM"
  icon.padding_left="$PADDINGS_NONE"
  icon.padding_right="$PADDINGS_NONE"

  label=""
  label.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_XSMALL"
  label.color="$WHITE"
  label.padding_left="$PADDINGS_SMALL"
  label.padding_right="$PADDINGS_LARGE"

  padding_left="$PADDINGS_SMALL"
  padding_right="$PADDINGS_XLARGE"

  background.drawing=off

  update_freq=0
  updates=when_shown
  script="$HOME/.config/sketchybar/plugins/packages.sh"
)

# --- Item Creation ----------------------------------------------------------
sketchybar --add item packages right \
  --set packages "${packages_config[@]}" \
  --subscribe packages mouse.entered mouse.exited control_center_update
