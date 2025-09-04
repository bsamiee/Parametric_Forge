#!/bin/bash
# Title         : space.sh
# Author        : Bardia Samiee (adapted from FelixKratz)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/space.sh
# ----------------------------------------------------------------------------
# Complete space visual state management - handles focus, hover, and app icons
# shellcheck disable=SC1091

set -euo pipefail

# Load configuration
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/plugins/icon_map.sh"

# --- Visual State Management ------------------------------------------------
update_space_visual_state() {
    local space_name="$1"
    local is_selected="$2"
    local event_type="$3"

    # Get app icons for this space
    local space_num
    space_num=$(echo "$space_name" | sed 's/space\.//')

    local icon_strip=" "
    if command -v yabai >/dev/null 2>&1; then
        local apps
        apps=$(yabai -m query --windows 2>/dev/null | jq -r --arg space "$space_num" '
            .[] | select(
                .space == ($space | tonumber) and
                .["has-ax-reference"] == true and
                .["is-minimized"] == false and
                .["is-hidden"] == false and
                (.layer // "") == "normal"
            ) | .app // empty' | sort -u 2>/dev/null || echo "")

        if [ -n "$apps" ]; then
            while IFS= read -r app; do
                [ -n "$app" ] && icon_strip+=" $(get_app_icon "$app")"
            done <<<"$apps"
        fi
    fi

    # Apply visual state based on selection and event
    if [ "$is_selected" = "true" ]; then
        # Active space - cyan system
        if [ -z "$apps" ] || [ "$icon_strip" = " " ]; then
            # Empty active space
            sketchybar --set "$space_name" \
                label="$icon_strip" \
                label.drawing=on \
                label.color="$BLACK" \
                label.background.color="$FAINT_CYAN" \
                icon.color="$PRIMARY_RED" \
                background.drawing=on \
                background.color="$PRIMARY_CYAN" \
                background.border_color="$CYAN" \
                background.border_width="$BORDER_THIN"
        else
            # Active space with apps
            sketchybar --set "$space_name" \
                label="$icon_strip" \
                label.drawing=on \
                label.color="$BLACK" \
                label.background.color="$FAINT_CYAN" \
                icon.color="$BLACK" \
                background.drawing=on \
                background.color="$PRIMARY_CYAN" \
                background.border_color="$CYAN" \
                background.border_width="$BORDER_THIN"
        fi
    else
        # Inactive space
        case "$event_type" in
            "mouse.entered")
                # Hover state - purple
                sketchybar --set "$space_name" \
                    label="$icon_strip" \
                    label.drawing=on \
                    label.color="$WHITE" \
                    icon.color="$WHITE" \
                    background.drawing=on \
                    background.color="$PRIMARY_PURPLE" \
                    background.border_color="$PURPLE" \
                    background.border_width="$BORDER_THIN"
                ;;
            "mouse.exited"|*)
                # Default inactive state
                if [ -z "$apps" ] || [ "$icon_strip" = " " ]; then
                    # Empty inactive space
                    sketchybar --set "$space_name" \
                        label="$icon_strip" \
                        label.drawing=on \
                        label.color="$WHITE" \
                        icon.color="$PRIMARY_RED" \
                        background.drawing=off \
                        background.color="$TRANSPARENT" \
                        background.border_color="$TRANSPARENT" \
                        background.border_width=0
                else
                    # Inactive space with apps
                    sketchybar --set "$space_name" \
                        label="$icon_strip" \
                        label.drawing=on \
                        label.color="$WHITE" \
                        icon.color="$WHITE" \
                        background.drawing=off \
                        background.color="$TRANSPARENT" \
                        background.border_color="$TRANSPARENT" \
                        background.border_width=0
                fi
                ;;
        esac
    fi
}

# --- Event Handlers ---------------------------------------------------------
# Handle focus state changes (triggered by yabai events)
if [ "$SELECTED" = "true" ]; then
    update_space_visual_state "$NAME" "true" "focus"
else
    update_space_visual_state "$NAME" "false" "focus"
fi

# Handle mouse events
case "$SENDER" in
    "mouse.entered")
        [ "$SELECTED" != "true" ] && update_space_visual_state "$NAME" "false" "mouse.entered"
        ;;
    "mouse.exited")
        [ "$SELECTED" != "true" ] && update_space_visual_state "$NAME" "false" "mouse.exited"
        ;;
    "mouse.clicked")
        [ -n "$SID" ] || exit 0
        if [ "$BUTTON" = "right" ]; then
            yabai -m space --destroy "$SID" 2>/dev/null || true
            sketchybar --trigger space_change --trigger windows_on_spaces 2>/dev/null || true
        else
            yabai -m space --focus "$SID" 2>/dev/null || true
        fi
        ;;
esac
