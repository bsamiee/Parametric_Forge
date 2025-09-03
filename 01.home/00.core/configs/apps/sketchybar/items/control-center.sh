#!/bin/bash
# Title         : control-center.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/control-center.sh
# ----------------------------------------------------------------------------
# Control Center button with expandable menu for system controls and third-party app shortcuts
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Menu Controls Array ----------------------------------------------------
menucontrols=(
    "Control__Center,Bluetooth"
    "Control__Center,AirDrop"
    "Control__Center,Stage__Manager"
    "Control__Center,Screen__Mirroring"
    "Control__Center,Do__Not__Disturb"
    "CleanMyMac"
    "1Password"
    "AlDente"
    "BetterMouse"
)

# --- String Conversion ------------------------------------------------------
controls_string=$(printf "%s " "${menucontrols[@]}")

# --- Button Configuration ---------------------------------------------------
separator_config=(
    icon="$CONTROL_CENTER"
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

# --- Item Creation ----------------------------------------------------------
sketchybar --add item control_center right \
    --set control_center "${separator_config[@]}" \
    --subscribe control_center mouse.clicked mouse.entered mouse.exited

# --- Event Creation ---------------------------------------------------------
sketchybar --add event control_center_update
