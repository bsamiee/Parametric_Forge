#!/bin/bash
# Title         : notifications.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/notifications.sh
# ----------------------------------------------------------------------------
# GitHub notifications counter with API integration
# shellcheck disable=SC1091

# --- Configuration --------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Token Validation -----------------------------------------------------
check_github_token() {
    [[ -n "$GITHUB_TOKEN" ]] || [[ -n "$GITHUB_CLASSIC_TOKEN" ]]
}

# --- API Request ----------------------------------------------------------
fetch_notifications() {
    local token

    # Prefer modern token, fallback to classic
    if [[ -n "$GITHUB_TOKEN" ]]; then
        token="$GITHUB_TOKEN"
    elif [[ -n "$GITHUB_CLASSIC_TOKEN" ]]; then
        token="$GITHUB_CLASSIC_TOKEN"
    else
        return 1
    fi

    # API call with timeout
    curl -m 15 -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $token" \
        "https://api.github.com/notifications" 2>/dev/null
}

# --- Display Update -------------------------------------------------------
update_notifications() {
    local icon color label

    if ! check_github_token; then
        # No token available - hide item completely
        apply_instant_change "$NAME" \
            width=0 \
            icon="" \
            label=""
        return
    fi

    # Fetch notifications
    local notifications curl_exit
    notifications=$(fetch_notifications)
    curl_exit=$?

    if [[ $curl_exit != 0 ]] || [[ -z "$notifications" ]]; then
        # API failure
        icon="$BELL_DISABLED"
        color="$GREY"
        label="--"
    else
        # Parse notification count
        local count
        count=$(echo "$notifications" | jq '. | length' 2>/dev/null || echo "0")

        if [[ "$count" -gt 0 ]]; then
            # Has notifications
            icon="$BELL_DOT"
            color="$RED"
            label="$count"
        else
            # No notifications
            icon="$BELL"
            color="$GREEN"
            label="0"
        fi
    fi

    # Update display
    apply_instant_change "$NAME" \
        icon="$icon" \
        icon.color="$color" \
        label="$label"
}

# --- Click Handler --------------------------------------------------------
handle_click() {
    handle_mouse_event "$NAME" "$SENDER"

    # Open GitHub notifications page
    open "https://github.com/notifications" 2>/dev/null || true
}

# --- Event Handler --------------------------------------------------------
case "$SENDER" in
    "mouse.clicked")
        handle_click
        ;;
    "mouse.entered"|"mouse.exited")
        # Use unified visual feedback system
        handle_mouse_event "$NAME" "$SENDER"
        ;;
    *)
        # Default: Update notifications display
        update_notifications
        ;;
esac
