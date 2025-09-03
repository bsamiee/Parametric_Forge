#!/bin/bash
# Title         : calendar.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/calendar.sh
# ----------------------------------------------------------------------------
# Enhanced calendar script with precise timing and right-click seconds display
# shellcheck disable=SC1091

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Precise Minute Synchronization -----------------------------------------
sync_to_minute_boundary() {
    local current_seconds
    current_seconds=$(date '+%S')
    if [ "$current_seconds" -ne 0 ]; then
        sleep $((60 - current_seconds))
        # Additional precision check
        while [[ $(date '+%S') != "00" ]]; do
            sleep 0.1
        done
    fi
}

# --- Right-Click Seconds Display --------------------------------------------
show_seconds_temporarily() {
    # Show seconds for 5 seconds on right-click
    for ((i = 0; i <= 4; ++i)); do
        sketchybar --set "$NAME" \
            label="$(date '+%a %b %-d %H:%M:%S')" \
            label.color="$PRIMARY_CYAN" \
            background.color="$FAINT_DARK_GREY" \
            background.drawing=on
        sleep 1
    done

    # Return to normal display
    sketchybar --set "$NAME" \
        label="$(date '+%a %b %-d %H:%M')" \
        label.color="$WHITE" \
        background.color="$TRANSPARENT" \
        background.drawing=off
}

# --- Handle Mouse Events ----------------------------------------------------
case "$SENDER" in
    "mouse.entered"|"mouse.exited")
        # Use unified visual feedback system
        handle_mouse_event "$NAME" "$SENDER"
        ;;
    "mouse.clicked")
        if [ "$BUTTON" = "right" ]; then
            # Right-click: Show seconds temporarily
            show_seconds_temporarily &
        else
            # Left-click: Use unified click feedback
            handle_mouse_event "$NAME" "$SENDER"
        fi
        ;;
    *)
        # Regular update with precise timing
        sync_to_minute_boundary
        ;;
esac

# --- Update Calendar Display ------------------------------------------------
sketchybar --set "$NAME" label="$(date '+%a %b %-d %H:%M')"
