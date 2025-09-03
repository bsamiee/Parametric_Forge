#!/bin/bash
# Title         : logo.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/logo.sh
# ----------------------------------------------------------------------------
# Apple logo with menu discovery and Mission Control integration
# shellcheck disable=SC1091

# --- Load Configuration Variables -------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Logo Configuration ----------------------------------------------------
logo_config=(
    icon="$APPLE"

    padding_left="$PADDINGS_XXLARGE"
    padding_right="$PADDINGS_LARGE"

    icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_LARGE"
    icon.color="$WHITE"
    icon.padding_left="$PADDINGS"
    icon.padding_right="$PADDINGS"

    label.drawing=off

    background.height="$((HEIGHT_BAR - 8))"
    background.border_width="$BORDER_MEDIUM"
    background.border_color="$GREY"
    background.color="$FAINT_BLACK"
    background.drawing=off

    click_script="$HOME/.config/sketchybar/plugins/logo.sh"
)

# --- Create Logo Item -------------------------------------------------------
sketchybar --add item logo left \
    --set logo "${logo_config[@]}" \
    --subscribe logo front_app_switched mouse.clicked mouse.entered mouse.exited