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
        icon="$CMD_KEY"
        label.drawing=off
        drawing=off

        icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_LARGE"
        icon.color="$WHITE"

        padding_left="$PADDINGS_SMALL"
        padding_right="$PADDINGS_MEDIUM"

        background.drawing=off

        click_script="$HOME/.config/sketchybar/plugins/logo.sh"
    )

    if [[ $i == 1 ]]; then
        menu_config+=(
            icon.font="$SYMBOL_FONT:$BOLD_WEIGHT:$SIZE_LARGE"
            icon.color="$GREEN"
        )
    fi

    sketchybar --add item "menu.$i" left \
        --set "menu.$i" "${menu_config[@]}" \
        --subscribe "menu.$i" mouse.clicked mouse.entered mouse.exited
done

# --- Bracket Creation -------------------------------------------------------
sketchybar --add bracket menus '/menu\..*/' \
    --set menus \
        background.height="$((HEIGHT_BAR - 8))" \
        background.border_width="$BORDER_MEDIUM" \
        background.border_color="$GREY" \
        background.color="$FAINT_BLACK" \
        background.corner_radius="$RADIUS_MEDIUM"
