#!/bin/bash
# Title         : separator.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/helpers/separator.sh
# ----------------------------------------------------------------------------
# Visual separator utility for SketchyBar sections
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Add Separator Function -------------------------------------------------
add_separator() {
    local separator_id="$1"
    local position="$2"      # left or right
    local separator_type="${3:-line}"  # line, dot, chevron_right, chevron_left

    # Select icon based on type
    local icon_symbol
    case "$separator_type" in
        "chevron_right")
            icon_symbol="$SEPARATOR_CHEVRON_RIGHT"
            ;;
        "chevron_left")
            icon_symbol="$SEPARATOR_CHEVRON_LEFT"
            ;;
        "dot")
            icon_symbol="$SEPARATOR_DOT"
            ;;
        "line"|*)
            icon_symbol="$SEPARATOR_LINE"
            ;;
    esac

    local separator_config=(
        icon="$icon_symbol"
        icon.color="$LIGHT_WHITE"
        icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM"
        icon.y_offset=0
        icon.padding_left="$PADDINGS_SMALL"
        icon.padding_right="$PADDINGS_SMALL"

        label.drawing=off
        background.drawing=off

        padding_left="$PADDINGS_SMALL"
        padding_right="$PADDINGS_SMALL"
    )

    # Create separator item
    sketchybar --add item "separator_$separator_id" "$position" \
        --set "separator_$separator_id" "${separator_config[@]}" 2>/dev/null || true
}

# --- Remove Separator Function ----------------------------------------------
remove_separator() {
    local separator_id="$1"
    sketchybar --remove "separator_$separator_id" 2>/dev/null || true
}

# --- Main Entry Point -------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Called directly - add separator with provided arguments
    add_separator "$@"
fi
