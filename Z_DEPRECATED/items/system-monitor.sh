#!/bin/bash
# Title         : system-monitor.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/system-monitor.sh
# ----------------------------------------------------------------------------
# Activity Monitor replacement with popup system
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"

# Main system monitor item with graph
sketchybar --add graph system_monitor right \
    --set system_monitor \
        script="$HOME/.config/sketchybar/plugins/graph.sh" \
        click_script="$HOME/.config/sketchybar/plugins/graph.sh" \
        \
        graph.color="$GREY" \
        graph.fill_color="$GREY" \
        graph.line_width=2 \
        \
        icon="$ACTIVITY" \
        icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
        icon.color="$PRIMARY_CYAN" \
        icon.padding_left="$PADDINGS_MEDIUM" \
        icon.padding_right="$PADDINGS_SMALL" \
        \
        label.drawing=off \
        \
        background.drawing=off \
        background.color="$TRANSPARENT" \
        \
        update_freq=3 \
        updates=on \
    --subscribe system_monitor mouse.entered mouse.exited mouse.clicked \
    \
    --add item system_monitor.percent right \
    --set system_monitor.percent \
        label="0%" \
        label.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_SMALL" \
        label.color="$WHITE" \
        label.padding_left="$PADDINGS_NONE" \
        label.padding_right="$PADDINGS_MEDIUM" \
        \
        icon.drawing=off \
        background.drawing=off \
    \
    --add item system_monitor.label right \
    --set system_monitor.label \
        label="Loading..." \
        label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_XSMALL" \
        label.color="$LIGHT_GREY" \
        label.max_chars=25 \
        label.padding_left="$PADDINGS_NONE" \
        label.padding_right="$PADDINGS_MEDIUM" \
        \
        icon.drawing=off \
        background.drawing=off

# Popup with detailed metrics
sketchybar --add item system_monitor.cpu popup.system_monitor \
    --set system_monitor.cpu \
        label="CPU    [----------]   0%" \
        label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
        label.color="$WHITE" \
        label.padding_left="$PADDINGS_MEDIUM" \
        label.padding_right="$PADDINGS_MEDIUM" \
        \
        icon.drawing=off \
        background.drawing=off \
    \
    --add item system_monitor.memory popup.system_monitor \
    --set system_monitor.memory \
        label="Memory [----------]   0%" \
        label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
        label.color="$WHITE" \
        label.padding_left="$PADDINGS_MEDIUM" \
        label.padding_right="$PADDINGS_MEDIUM" \
        \
        icon.drawing=off \
        background.drawing=off \
    \
    --add item system_monitor.disk popup.system_monitor \
    --set system_monitor.disk \
        label="Disk   [----------]   0%" \
        label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
        label.color="$WHITE" \
        label.padding_left="$PADDINGS_MEDIUM" \
        label.padding_right="$PADDINGS_MEDIUM" \
        \
        icon.drawing=off \
        background.drawing=off \
    \
    --add item system_monitor.network popup.system_monitor \
    --set system_monitor.network \
        label="Network[----------]   0%" \
        label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
        label.color="$WHITE" \
        label.padding_left="$PADDINGS_MEDIUM" \
        label.padding_right="$PADDINGS_MEDIUM" \
        \
        icon.drawing=off \
        background.drawing=off \
    \
    --add item system_monitor.power popup.system_monitor \
    --set system_monitor.power \
        label="Power  [----------]   0W" \
        label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
        label.color="$WHITE" \
        label.padding_left="$PADDINGS_MEDIUM" \
        label.padding_right="$PADDINGS_MEDIUM" \
        \
        icon.drawing=off \
        background.drawing=off
