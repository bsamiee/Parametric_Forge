#!/bin/bash
# Title         : logo.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/logo.sh
# ----------------------------------------------------------------------------
# Apple logo menu toggle and menu bar discovery functionality
# shellcheck disable=SC1091

set -euo pipefail

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

MENUBAR_CMD="$HOME/.config/sketchybar/menubar"
STATE_FILE="/tmp/sketchybar_logo_menu_state"

if [[ -z "${WHITE:-}" ]] || [[ -z "${GREEN:-}" ]]; then
    echo "ERROR: Colors not loaded properly in logo plugin context" >&2
    exit 1
fi

# --- Utility Functions ------------------------------------------------------
set_item_properties() {
    local item="$1"; shift
    sketchybar --set "$item" "$@" 2>/dev/null || true
}

animate_item_properties() {
    local item="$1" curve="${2:-tanh}" duration="${3:-15}"; shift 3
    sketchybar --animate "$curve" "$duration" --set "$item" "$@" 2>/dev/null || true
}

# --- State Management -------------------------------------------------------
logo_menu_on() {
    echo "on" > "$STATE_FILE"
    # Hide spaces and focus_app, show menu items
    for space in $(sketchybar --query spaces 2>/dev/null | jq -r '.bracket[]? // empty' 2>/dev/null); do
        [[ -n "$space" ]] && sketchybar --set "$space" drawing=off
    done

    sketchybar --set spaces drawing=off 2>/dev/null || true
    sketchybar --set focus_app drawing=off 2>/dev/null || true

    # Activate logo appearance (menu active): show bg with standard hover styling (no border)
    animate_item_properties "logo" tanh 15 \
        background.drawing=on \
        background.color="$FAINT_GREY" \
        background.corner_radius="$RADIUS_LARGE" \
        icon.color="$GREEN" \
        icon="$APPLE" \
        icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_LARGE"

    # Show menu bracket and items
    sketchybar --set menus drawing=on 2>/dev/null || true
    update_menu_items

    # Auto-hide after 30 seconds
    (sleep 30 && logo_menu_off) &
}

logo_menu_off() {
    echo "off" > "$STATE_FILE"
    # Restore spaces and focus_app
    for space in $(sketchybar --query spaces 2>/dev/null | jq -r '.bracket[]? // empty' 2>/dev/null); do
        [[ -n "$space" ]] && sketchybar --set "$space" drawing=on
    done

    sketchybar --set spaces drawing=on 2>/dev/null || true
    sketchybar --set focus_app drawing=on 2>/dev/null || true

    # Restore logo appearance EXACTLY to item defaults (no border)
    animate_item_properties "logo" tanh 15 \
        background.drawing=off \
        background.color="$TRANSPARENT" \
        background.border_color="$TRANSPARENT" \
        background.border_width="$BORDER_NONE" \
        background.corner_radius="$RADIUS_LARGE" \
        icon.color="$WHITE" \
        icon="$APPLE" \
        icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_LARGE"

    # Hide menu bracket and all menu items
    sketchybar --set menus drawing=off 2>/dev/null || true
    for ((i = 1; i <= 14; ++i)); do
        sketchybar --set "menu.$i" drawing=off 2>/dev/null || true
    done
}

update_menu_items() {
    local mid=1

    # Get menu items from menubar and populate
    while IFS= read -r menu && [[ $mid -le 14 ]]; do
        if [[ -n "$menu" ]]; then
            sketchybar --set "menu.$mid" icon="$menu" drawing=on 2>/dev/null || true
        fi
        ((mid++))
    done < <("$MENUBAR_CMD" -l 2>/dev/null || true)

    # Hide remaining unused menu items
    while [[ $mid -le 14 ]]; do
        sketchybar --set "menu.$mid" drawing=off 2>/dev/null || true
        ((mid++))
    done
}

get_logo_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "off"
    fi
}

# --- Event Handling ---------------------------------------------------------
case "$NAME" in
    "logo")
        case "$SENDER" in
            "mouse.clicked")
                state=$(get_logo_state)

                if [[ "${BUTTON:-}" == "right" ]]; then
                    # Right click: Toggle menu
                    if [[ "$state" == "off" ]]; then
                        logo_menu_on
                    else
                        logo_menu_off
                    fi
                elif [[ "${MODIFIER:-}" == "shift" ]]; then
                    # Shift+click: Reload SketchyBar
                    sketchybar --reload
                else
                    # Left click: Mission Control or menu close
                    if [[ "$state" == "off" ]]; then
                        /System/Applications/Mission\ Control.app/Contents/MacOS/Mission\ Control &
                    else
                        menubar -s 0 2>/dev/null || true
                    fi
                fi
                ;;
            "front_app_switched")
                # Update menu items if logo menu is active
                state=$(get_logo_state)
                if [[ "$state" == "on" ]]; then
                    update_menu_items
                    sleep 1
                    update_menu_items  # Double update for reliability
                fi
                ;;
            "mouse.entered")
                state=$(get_logo_state)
                if [[ "$state" == "off" ]]; then
                    set_item_properties "logo" \
                        background.drawing=on \
                        background.color="$FAINT_GREY" \
                        background.corner_radius="$RADIUS_LARGE"
                fi
                ;;
            "mouse.exited")
                state=$(get_logo_state)
                if [[ "$state" == "off" ]]; then
                    set_item_properties "logo" \
                        background.drawing=off \
                        background.border_width="$BORDER_NONE" \
                        background.border_color="$TRANSPARENT" \
                        background.color="$TRANSPARENT"
                fi
                ;;
        esac
        ;;
    menu.*)
        # Handle menu.X item clicks - extract number and trigger menubar
        case "$SENDER" in
            "mouse.clicked")
                menu_index=$(echo "$NAME" | cut -d '.' -f 2)
                # Use the same resolved menubar binary used for listing
                "$MENUBAR_CMD" -s "$menu_index" 2>/dev/null || true
                # Collapse menu after selection
                logo_menu_off
                ;;
            "mouse.entered"|"mouse.exited")
                # TODO: Add hover effects for menu items if needed
                ;;
        esac
        ;;
esac
