#!/bin/bash
# Title         : calendar.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/calendar.sh
# ----------------------------------------------------------------------------
# Simple toggle calendar: right-click switches between normal/seconds mode
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# Simple state file - just stores "seconds" or "normal"
STATE_FILE="/tmp/sketchybar_calendar_mode"

# --- State Management -------------------------------------------------------
get_mode() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "normal"
    fi
}

toggle_mode() {
    current=$(get_mode)
    if [ "$current" = "seconds" ]; then
        echo "normal" > "$STATE_FILE"
    else
        echo "seconds" > "$STATE_FILE"
    fi
}

# --- Display Update ---------------------------------------------------------
update_display() {
    local mode="$1"

    case "$mode" in
        "seconds")
            sketchybar --set "$NAME" label="$(date '+%a %b %-d %H:%M:%S')"
            ;;
        "normal"|*)
            sketchybar --set "$NAME" label="$(date '+%a %b %-d %H:%M')"
            ;;
    esac
}

# --- Event Handling ---------------------------------------------------------
case "$SENDER" in
    "mouse.entered"|"mouse.exited")
        # Standard hover behavior
        handle_mouse_event "$NAME" "$SENDER"
        ;;
    "mouse.clicked")
        if [ "$BUTTON" = "right" ]; then
            # Right-click: Toggle mode
            toggle_mode
            current_mode=$(get_mode)
            update_display "$current_mode"
        elif [ "$BUTTON" = "middle" ]; then
            # Middle-click: Open system calendar widget
            osascript -e 'tell application "System Events" to click menu bar item 1 of menu bar 1 of application process "ControlCenter"' &
            handle_mouse_event "$NAME" "$SENDER"
        else
            # Left-click: Open Notification Center
            osascript -e 'tell application "System Events" to click menu bar item "NotificationCenter" of menu bar 1 of application process "ControlCenter"' &
            handle_mouse_event "$NAME" "$SENDER"
        fi
        ;;
    *)
        # Regular update - just display current mode
        current_mode=$(get_mode)
        update_display "$current_mode"
        ;;
esac