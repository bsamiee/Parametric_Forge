#!/bin/bash
# Title         : logo.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/logo.sh
# ----------------------------------------------------------------------------
# Apple logo with menu discovery and Mission Control integration
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Logo Configuration -----------------------------------------------------
logo_config=(
    icon="$APPLE"

    # Move closer to the bar's left edge (match calendar's outer padding)
    padding_left="$PADDINGS_NONE"
    padding_right="$PADDINGS_XXLARGE"

    icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_LARGE"
    icon.color="$WHITE"
    # Widen background by increasing inner icon padding one step
    icon.padding_left="$PADDINGS_LARGE"
    icon.padding_right="$PADDINGS_LARGE"

    label.drawing=off

    background.color="$TRANSPARENT"
    background.height="$HEIGHT_ITEM"
    # Ensure no border/fill is visible by default
    background.border_width="$BORDER_NONE"
    background.border_color="$TRANSPARENT"
    background.corner_radius="$RADIUS_LARGE"
    # Make hover/active background slightly wider (one step up)
    background.padding_left="$PADDINGS_LARGE"
    background.padding_right="$PADDINGS_LARGE"
    background.drawing=off

    script="$HOME/.config/sketchybar/plugins/logo.sh"
)

# --- Item Creation ----------------------------------------------------------
sketchybar --add item logo left \
    --set logo "${logo_config[@]}" \
    --subscribe logo front_app_switched mouse.clicked mouse.entered mouse.exited
