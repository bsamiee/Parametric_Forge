#!/bin/bash
# Title         : controls.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/controls.sh
# ----------------------------------------------------------------------------
# Menu bar controls integration using SketchyBar aliases
# shellcheck disable=SC1091

# --- Load Configuration Variables -------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"

# --- Menu Controls Array (Add/Remove as needed) ----------------------------
menucontrols=(
    "Control__Center,Bluetooth"
    "Control__Center,AirDrop"
    "Control__Center,Stage__Manager"
    "Control__Center,Screen__Mirroring"
    "Control__Center,Do__Not__Disturb"
    "CleanMyMac"
    "1Password__7"
    "AlDente"
    "BetterMouse"
)

# --- Convert underscores to spaces for actual menu item names --------------
menuitem=()
for item in "${menucontrols[@]}"; do
    new_item=${item//__/ }
    menuitem+=("$new_item")
done

# --- Create Alias Items for Each Menu Control -------------------------------
for item in "${menuitem[@]}"; do
    alias_config=(
        drawing=off
        padding_left=-2
        padding_right=-6
        alias.color="$WHITE"
        label.drawing=off
        icon.drawing=off
        click_script="$HOME/.config/sketchybar/plugins/controls.sh"
    )

    sketchybar --add alias "$item" right \
        --set "$item" "${alias_config[@]}" \
        --subscribe "$item" mouse.clicked mouse.entered mouse.exited
done
