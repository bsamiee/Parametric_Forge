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
    local date_part time_hm time_sec day mon dom

    # Desired format: "[FRI] - SEP 5 -" (icon) + "00:00" or "00:00:00" (label)
    day=$(date '+%a' | tr '[:lower:]' '[:upper:]')
    mon=$(date '+%b' | tr '[:lower:]' '[:upper:]')
    dom=$(date '+%-d')
    date_part="[$day] - $mon $dom -"

    case "$mode" in
        "seconds")
            time_hm=$(date '+%H:%M')
            time_sec=$(date '+%S')
            # Main item: HH:MM in cyan
            sketchybar --set calendar \
                icon="$date_part" \
                icon.color="$WHITE" \
                label="$time_hm" \
                label.color="$PRIMARY_CYAN"
            # Suffix item: :SS in red
            sketchybar --set calendar_secs \
                label=":$time_sec" \
                label.color="$RED" \
                drawing=on
            ;;
        "normal"|*)
            time_hm=$(date '+%H:%M')
            # Main item: HH:MM in cyan
            sketchybar --set calendar \
                icon="$date_part" \
                icon.color="$WHITE" \
                label="$time_hm" \
                label.color="$PRIMARY_CYAN"
            # Hide seconds suffix
            sketchybar --set calendar_secs drawing=off
            ;;
    esac
}

# --- Event Handling ---------------------------------------------------------
case "$SENDER" in
    "mouse.entered")
        # Turn on shared bracket background for both items
        sketchybar --set calendar_group background.drawing=on background.color="$FAINT_GREY"
        ;;
    "mouse.exited")
        # Turn off shared bracket background
        sketchybar --set calendar_group background.drawing=off
        ;;
    "mouse.clicked")
        if [ "$BUTTON" = "right" ]; then
            # Right-click: Toggle mode
            toggle_mode
            current_mode=$(get_mode)
            update_display "$current_mode"
        fi
        ;;
    *)
        # Regular update - just display current mode
        current_mode=$(get_mode)
        update_display "$current_mode"
        ;;
esac
