#!/bin/bash
# Title         : front_app.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/front_app.sh
# ----------------------------------------------------------------------------
# Enhanced front app plugin with visual feedback (text-only)
# shellcheck disable=SC1091

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Get Current Application ------------------------------------------------
get_current_app() {
    # Try to get app from yabai, fallback to native methods
    local current_app
    current_app=$(yabai -m query --windows --window 2>/dev/null | jq -r '.app // empty' 2>/dev/null)

    # Fallback methods if yabai fails
    if [[ -z "$current_app" || "$current_app" == "null" ]]; then
        # Use AppleScript as fallback
        current_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || echo "Desktop")
    fi

    # Handle special cases
    if [[ -z "$current_app" || "$current_app" == "null" ]]; then
        current_app="Desktop"
    fi

    echo "$current_app"
}

# --- Update Front App Display -----------------------------------------------
update_front_app() {
    local app_name

    # Get current application
    app_name=$(get_current_app)

    # Update the item display (text-only)
    sketchybar --set "$NAME" label="$app_name" 2>/dev/null || true
}

# --- Handle Click Events ----------------------------------------------------
handle_click() {
    # Use visual feedback for click
    handle_mouse_event "$NAME" "$SENDER"

    # Toggle window floating state with yabai
    if command -v yabai >/dev/null 2>&1; then
        yabai -m window --toggle float 2>/dev/null || true
    fi
}

# --- Main Event Handler -----------------------------------------------------
case "$SENDER" in
    "front_app_switched"|"window_focus"|"system_woke")
        # Update app display when focus changes
        update_front_app
        ;;
    "mouse.entered"|"mouse.exited")
        # Use unified visual feedback system
        handle_mouse_event "$NAME" "$SENDER"
        ;;
    "mouse.clicked")
        # Handle click with visual feedback and functionality
        handle_click
        ;;
    *)
        # Default: Update display
        update_front_app
        ;;
esac
