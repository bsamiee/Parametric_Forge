#!/bin/bash
# Title         : more-menu.sh
# Author        : Bardia Samiee (adapted from reference)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/more-menu.sh
# ----------------------------------------------------------------------------
# Collapsible menu toggle button using our infrastructure
# shellcheck disable=SC1091

# --- Load Configuration Variables -------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Menu Controls Array (Must match controls.sh) -------------------------
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

# --- Convert array to space-separated string for plugin --------------------
controls_string=$(printf "%s " "${menucontrols[@]}")

# --- Toggle Button Configuration -------------------------------------------
separator_config=(
    icon="􀯶"
    icon.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_LARGE"
    icon.color="$GREY"
    icon.padding_left="$PADDINGS_LARGE"
    icon.padding_right="$PADDINGS_LARGE"

    label.drawing=off

    padding_left="$PADDINGS_NONE"
    padding_right="$PADDINGS_NONE"

    background.drawing=off

    click_script="$HOME/.config/sketchybar/plugins/controls.sh \"$controls_string\""
)

# --- Create Toggle Button --------------------------------------------------
sketchybar --add item more_menu right \
    --set more_menu "${separator_config[@]}" \
    --subscribe more_menu mouse.clicked mouse.entered mouse.exited

# --- Create Custom Event ---------------------------------------------------
sketchybar --add event more_menu_update
