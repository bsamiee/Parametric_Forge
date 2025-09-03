#!/bin/bash
# Title         : battery.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/battery.sh
# ----------------------------------------------------------------------------
# Advanced battery management item with AlDente-like functionality
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

# Battery item with comprehensive functionality
sketchybar --add item battery right \
    --set battery \
    update_freq=30 \
    \
    icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
    icon.color="$WHITE" \
    icon.padding_left="$PADDINGS_SMALL" \
    icon.padding_right="$PADDINGS_SMALL" \
    \
    label.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
    label.color="$WHITE" \
    label.padding_left="$PADDINGS_SMALL" \
    label.padding_right="$PADDINGS_MEDIUM" \
    \
    background.color="$TRANSPARENT" \
    background.corner_radius="$RADIUS_MEDIUM" \
    background.height="$HEIGHT_ITEM" \
    background.drawing=off \
    \
    popup.align=right \
    popup.height=200 \
    popup.background.color="$PRIMARY_DARK_GREY" \
    popup.background.corner_radius="$RADIUS_LARGE" \
    popup.background.shadow.drawing=on \
    popup.background.shadow.color="$SHADOW_HEAVY" \
    popup.background.shadow.angle="$SHADOW_ANGLE" \
    popup.background.shadow.distance="$SHADOW_DISTANCE" \
    \
    script="$PLUGIN_DIR/battery.sh" \
    click_script="$PLUGIN_DIR/battery.sh" \
    \
    --subscribe battery system_woke power_source_change \
    \
    --add item battery.details popup.battery \
    --set battery.details \
    icon="" \
    label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
    label.color="$GREY" \
    label.padding_left="$PADDINGS_MEDIUM" \
    label.padding_right="$PADDINGS_MEDIUM" \
    background.drawing=off \
    \
    --add item battery.health popup.battery \
    --set battery.health \
    icon="$BATTERY_HEALTH" \
    label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
    label.color="$GREY" \
    label.padding_left="$PADDINGS_MEDIUM" \
    label.padding_right="$PADDINGS_MEDIUM" \
    background.drawing=off \
    \
    --add item battery.limit popup.battery \
    --set battery.limit \
    icon="$BATTERY_CHARGING" \
    label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
    label.color="$GREY" \
    label.padding_left="$PADDINGS_MEDIUM" \
    label.padding_right="$PADDINGS_MEDIUM" \
    background.drawing=off \
    click_script="$PLUGIN_DIR/battery.sh limit 80"

# --- Battery Charge Limit Presets ------------------------------------------
# Simplified preset creation without function calls during item creation
sketchybar --add item "battery.preset50" popup.battery \
    --set "battery.preset50" \
    icon="$BATTERY_50" \
    label="50%" \
    label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
    label.color="$GREY" \
    label.padding_left="$PADDINGS_SMALL" \
    label.padding_right="$PADDINGS_SMALL" \
    background.drawing=off \
    click_script="$PLUGIN_DIR/battery.sh limit 50" \
    \
    --add item "battery.preset70" popup.battery \
    --set "battery.preset70" \
    icon="$BATTERY_75" \
    label="70%" \
    label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
    label.color="$GREY" \
    label.padding_left="$PADDINGS_SMALL" \
    label.padding_right="$PADDINGS_SMALL" \
    background.drawing=off \
    click_script="$PLUGIN_DIR/battery.sh limit 70" \
    \
    --add item "battery.preset80" popup.battery \
    --set "battery.preset80" \
    icon="$BATTERY_75" \
    label="80%" \
    label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
    label.color="$GREY" \
    label.padding_left="$PADDINGS_SMALL" \
    label.padding_right="$PADDINGS_SMALL" \
    background.drawing=off \
    click_script="$PLUGIN_DIR/battery.sh limit 80" \
    \
    --add item "battery.preset90" popup.battery \
    --set "battery.preset90" \
    icon="$BATTERY_100" \
    label="90%" \
    label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
    label.color="$GREY" \
    label.padding_left="$PADDINGS_SMALL" \
    label.padding_right="$PADDINGS_SMALL" \
    background.drawing=off \
    click_script="$PLUGIN_DIR/battery.sh limit 90" \
    \
    --add item "battery.preset100" popup.battery \
    --set "battery.preset100" \
    icon="$BATTERY_100" \
    label="100%" \
    label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
    label.color="$GREY" \
    label.padding_left="$PADDINGS_SMALL" \
    label.padding_right="$PADDINGS_SMALL" \
    background.drawing=off \
    click_script="$PLUGIN_DIR/battery.sh limit 100"

sketchybar --add item battery.adapter popup.battery \
    --set battery.adapter \
    icon="$BATTERY_ADAPTER" \
    label="Toggle Adapter" \
    label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
    label.color="$GREY" \
    label.padding_left="$PADDINGS_MEDIUM" \
    label.padding_right="$PADDINGS_MEDIUM" \
    background.drawing=off \
    click_script="$PLUGIN_DIR/battery.sh adapter" \
    \
    --add item battery.calibrate popup.battery \
    --set battery.calibrate \
    icon="$BATTERY_CALIBRATE" \
    label="Calibrate Battery" \
    label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
    label.color="$GREY" \
    label.padding_left="$PADDINGS_MEDIUM" \
    label.padding_right="$PADDINGS_MEDIUM" \
    background.drawing=off \
    click_script="$PLUGIN_DIR/battery.sh calibrate"