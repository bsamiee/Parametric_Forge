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

# --- Configuration --------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# Validate essential constants are loaded
if [[ -z "${WHITE:-}" ]] || [[ -z "${GREEN:-}" ]]; then
    echo "ERROR: Colors not loaded properly in logo plugin context" >&2
    exit 1
fi

# Set up menubar command (use local binary if available)
MENUBAR_CMD="$HOME/.config/sketchybar/menubar"
if [[ ! -x "$MENUBAR_CMD" ]]; then
    echo "ERROR: menubar binary not found at $MENUBAR_CMD" >&2
    exit 1
fi

# --- State Management -----------------------------------------------------
logo_menu_on() {
    # Hide spaces and front_app, show menu items
    for space in $(sketchybar --query spaces 2>/dev/null | jq -r '.bracket[]? // empty' 2>/dev/null); do
        [[ -n "$space" ]] && sketchybar --set "$space" drawing=off
    done

    sketchybar --set spaces drawing=off 2>/dev/null || true
    sketchybar --set front_app drawing=off 2>/dev/null || true

    # Activate logo appearance using existing animation system
    apply_smooth_animation "logo" 15 \
        background.drawing=on \
        icon.color="$GREEN" \
        icon="$APPLE" \
        icon.font="$SYMBOL_FONT:$BOLD_WEIGHT:17.0" \
        icon.y_offset=1 \
        padding_right="$PADDINGS_LARGE" \
        padding_left="$PADDINGS_LARGE"

    # Update and show menu items
    update_menu_items

    # Auto-hide after 30 seconds
    (sleep 30 && logo_menu_off) &
}

logo_menu_off() {
    # Restore spaces and front_app
    for space in $(sketchybar --query spaces 2>/dev/null | jq -r '.bracket[]? // empty' 2>/dev/null); do
        [[ -n "$space" ]] && sketchybar --set "$space" drawing=on
    done

    sketchybar --set spaces drawing=on 2>/dev/null || true
    sketchybar --set front_app drawing=on 2>/dev/null || true

    # Restore logo appearance using existing animation system
    apply_smooth_animation "logo" 15 \
        background.drawing=off \
        icon.color="$WHITE" \
        icon="$APPLE" \
        icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_LARGE" \
        icon.y_offset=0 \
        padding_right="$PADDINGS_LARGE" \
        padding_left="$PADDINGS_LARGE"

    # Hide all menu items
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
    sketchybar --query logo 2>/dev/null | jq -r '.geometry.background.drawing // "off"' 2>/dev/null || echo "off"
}

# --- Event Handler -------------------------------------------------------
case "$NAME" in
    "logo")
        case "$SENDER" in
            "mouse.clicked")
                handle_mouse_event "$NAME" "$SENDER"

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
            "mouse.entered"|"mouse.exited")
                handle_mouse_event "$NAME" "$SENDER"
                ;;
        esac
        ;;
    menu.*)
        # Handle menu.X item clicks - extract number and trigger menubar
        case "$SENDER" in
            "mouse.clicked")
                menu_index=$(echo "$NAME" | cut -d '.' -f 2)
                menubar -s "$menu_index" 2>/dev/null || true
                ;;
            "mouse.entered"|"mouse.exited")
                handle_mouse_event "$NAME" "$SENDER"
                ;;
        esac
        ;;
esac
