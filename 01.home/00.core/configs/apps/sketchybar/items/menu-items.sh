#!/bin/bash
# Title         : menu-items.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/menu-items.sh
# ----------------------------------------------------------------------------
# Numbered menu items for logo-triggered menu bar discovery
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Menu Item Creation -----------------------------------------------------
for ((i = 1; i <= 14; ++i)); do
    menu_config=(
        icon="$i"
        label.drawing=off
        drawing=off

        # Use project text font, light weight, 10pt
        icon.font="$TEXT_FONT:$LIGHT_WEIGHT:$SIZE_MEDIUM"
        icon.color="$WHITE"

        padding_left="$PADDINGS_SMALL"
        padding_right="$PADDINGS_MEDIUM"

        background.drawing=off

        script="$HOME/.config/sketchybar/plugins/logo.sh"
    )

    sketchybar --add item "menu.$i" left \
        --set "menu.$i" "${menu_config[@]}" \
        --subscribe "menu.$i" mouse.clicked mouse.entered mouse.exited
done

# --- Bracket Creation -------------------------------------------------------
sketchybar --add bracket menus '/menu\..*/' \
    --set menus \
        drawing=off \
        background.height="$HEIGHT_ITEM" \
        background.border_width="$BORDER_THIN" \
        background.border_color="$LIGHT_WHITE" \
        background.color="$TRANSPARENT" \
        background.corner_radius="$RADIUS_LARGE"
