#!/bin/bash
# Title         : packages.sh
# Author        : Bardia Samiee (adapted from reference)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/packages.sh
# ----------------------------------------------------------------------------
# System-wide package counter across all package managers
# shellcheck disable=SC1091

# --- Load Configuration Variables -------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Packages Item Configuration --------------------------------------------
packages_config=(
  position=right

  # Hidden by default (shown via more-menu toggle)
  drawing=off

  # Visual styling
  icon="$PACKAGE"
  icon.color="$PINK"
  icon.font="$SYMBOL_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM"
  icon.padding_left="$PADDINGS_NONE"
  icon.padding_right="$PADDINGS_NONE"

  # Label configuration
  label=""
  label.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_XSMALL"
  label.color="$WHITE"
  label.padding_left="$PADDINGS_SMALL"
  label.padding_right="$PADDINGS_LARGE"

  # Positioning and spacing
  padding_left="$PADDINGS_SMALL"
  padding_right="$PADDINGS_XLARGE"

  # No background drawing
  background.drawing=off

  # Update only when shown (packages change infrequently)
  update_freq=0
  updates=when_shown

  # Scripts and functionality
  script="$HOME/.config/sketchybar/plugins/packages.sh"
)

# --- Create Packages Item ---------------------------------------------------
sketchybar --add item packages right \
  --set packages "${packages_config[@]}" \
  --subscribe packages mouse.entered mouse.exited more_menu_update
