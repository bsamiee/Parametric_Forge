#!/bin/bash
# Title         : space.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/space.sh
# ----------------------------------------------------------------------------
# Individual space visual state management with focus, hover, and app icons
# shellcheck disable=SC1091

set -euo pipefail

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/plugins/icon_map.sh"

# --- Utility Functions ------------------------------------------------------
set_item_properties() {
    local item="$1"; shift
    sketchybar --set "$item" "$@" 2>/dev/null || true
}

# --- Visual State Management ------------------------------------------------
update_space_visual_state() {
    local space_name="$1"
    local is_selected="$2"
    local event_type="$3"

    # Get app icons for this space
    local space_num
    space_num=${space_name#space.}

    local icon_strip=" "
    local min_icon_strip=" "
    if command -v yabai >/dev/null 2>&1; then
        local apps="" mins=""
        if command -v jq >/dev/null 2>&1; then
            apps=$(yabai -m query --windows 2>/dev/null | jq -r --arg space "$space_num" '
                .[] | select(
                    .space == ($space | tonumber) and
                    ((."is-minimized" // false) == false) and
                    ((."is-sticky" // false) == false) and
                    ((."is-hidden" // false) == false) and
                    ((.layer // "") == "normal") and
                    ((.role // "") == "AXWindow") and
                    ((.subrole // "") == "AXStandardWindow")
                ) | .app // empty' | sort -u 2>/dev/null || echo "")

            mins=$(yabai -m query --windows 2>/dev/null | jq -r --arg space "$space_num" '
                .[] | select(
                    .space == ($space | tonumber) and
                    ((."is-minimized" // false) == true) and
                    ((."is-sticky" // false) == false) and
                    ((."is-hidden" // false) == false) and
                    ((.layer // "") == "normal") and
                    ((.role // "") == "AXWindow") and
                    ((.subrole // "") == "AXStandardWindow")
                ) | .app // empty' | sort -u 2>/dev/null || echo "")
        fi

        if [ -n "$apps" ]; then
            while IFS= read -r app; do
                [ -n "$app" ] && icon_strip+=" $(get_app_icon "$app")"
            done <<<"$apps"
        fi

        if [ -n "$mins" ]; then
            while IFS= read -r app; do
                [ -n "$app" ] && min_icon_strip+=" $(get_app_icon "$app")"
            done <<<"$mins"
        fi
    fi

    # Compose label only with open (non-minimized) app icons
    local label_content="$icon_strip"

    # Apply visual state based on selection and event using helper
    # Slightly reduce item background height so bracket border remains visible
    local ITEM_BG_HEIGHT=$((HEIGHT_ITEM - 2))

    if [ "$is_selected" = "true" ]; then
        # Active space - cyan system
        if [ -z "$apps" ] || [ "$icon_strip" = " " ]; then
            # Empty active space
            set_item_properties "$space_name" \
                label="$label_content" \
                label.drawing=on \
                label.color="$BLACK" \
                icon.color="$BLACK" \
                label.background.color="$FAINT_CYAN" \
                background.drawing=on \
                background.color="$PRIMARY_CYAN" \
                background.height="$ITEM_BG_HEIGHT" \
                background.border_color="$LIGHT_WHITE" \
                background.border_width="$BORDER_THIN"
        else
            # Active space with apps
            set_item_properties "$space_name" \
                label="$label_content" \
                label.drawing=on \
                label.color="$BLACK" \
                icon.color="$BLACK" \
                label.background.color="$FAINT_CYAN" \
                background.drawing=on \
                background.color="$PRIMARY_CYAN" \
                background.height="$ITEM_BG_HEIGHT" \
                background.border_color="$LIGHT_WHITE" \
                background.border_width="$BORDER_THIN"
        fi
    else
        # Inactive space
        case "$event_type" in
            "mouse.entered")
                # Hover state - grey (matches WezTerm hover)
                set_item_properties "$space_name" \
                    label="$label_content" \
                    label.drawing=on \
                    label.color="$WHITE" \
                    icon.color="$WHITE" \
                    background.drawing=on \
                    background.color="$FAINT_GREY" \
                    background.height="$ITEM_BG_HEIGHT" \
                    background.border_color="$LIGHT_WHITE" \
                    background.border_width="$BORDER_THIN"
                ;;
            "mouse.exited"|*)
                # Default inactive state
                if [ -z "$apps" ] || [ "$icon_strip" = " " ]; then
                    # Empty inactive space
                    set_item_properties "$space_name" \
                        label="$label_content" \
                        label.drawing=on \
                        label.color="$WHITE" \
                        icon.color="$WHITE" \
                        label.background.color="$TRANSPARENT" \
                        background.drawing=off \
                        background.color="$TRANSPARENT" \
                        background.border_color="$TRANSPARENT" \
                        background.border_width="$BORDER_NONE"
                else
                    # Inactive space with apps
                    set_item_properties "$space_name" \
                        label="$label_content" \
                        label.drawing=on \
                        label.color="$WHITE" \
                        icon.color="$WHITE" \
                        label.background.color="$TRANSPARENT" \
                        background.drawing=off \
                        background.color="$TRANSPARENT" \
                        background.border_color="$TRANSPARENT" \
                        background.border_width="$BORDER_NONE"
                fi
                ;;
        esac
    fi
}

# --- Event Handling ---------------------------------------------------------
case "$SENDER" in
    "space_change"|"pf_space_change"|"space_windows_change")
        # Update visual state; if $SELECTED is missing (custom events), derive selection via yabai
        sel="${SELECTED:-}"
        if [ -z "$sel" ]; then
            # Derive selection by comparing current focused space id with this component's $SID
            current_sid=$(yabai -m query --spaces --space 2>/dev/null | jq -r '.id // 0')
            if [ "$current_sid" = "${SID:-}" ]; then sel=true; else sel=false; fi
        fi
        if [ "$sel" = "true" ]; then
            update_space_visual_state "$NAME" "true" "focus"
        else
            update_space_visual_state "$NAME" "false" "focus"
        fi
        ;;
    "mouse.entered")
        # Hover effect for inactive spaces only
        [ "${SELECTED:-}" != "true" ] && update_space_visual_state "$NAME" "false" "mouse.entered"
        ;;
    "mouse.exited")
        # Restore state for inactive spaces only
        [ "${SELECTED:-}" != "true" ] && update_space_visual_state "$NAME" "false" "mouse.exited"
        ;;
    "mouse.clicked")
        # Only handle right-click here. Left-click focus is handled via click_script
        # Be robust when $SID is not provided by deriving the space from $NAME
        target_sel="${SID:-}"
        if [ -z "$target_sel" ]; then
            # NAME is expected like space.N
            space_num="${NAME#space.}"
            case "$space_num" in
                ''|*[!0-9]*) ;; # non-numeric, ignore
                *) target_sel="$space_num" ;;
            esac
        fi

        if [ "${BUTTON:-}" = "right" ] && [ -n "$target_sel" ]; then
            yabai -m space "$target_sel" --destroy 2>/dev/null || true
            sketchybar --trigger pf_space_change 2>/dev/null || true
        fi
        ;;
esac
