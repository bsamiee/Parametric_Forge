#!/bin/bash
# Title         : window_state.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/window_state.sh
# ----------------------------------------------------------------------------
# Window state visualization and focused app display with yabai integration
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/constants.sh"

# --- Utilities --------------------------------------------------------------
set_item_properties() {
    local item="$1"; shift
    sketchybar --set "$item" "$@" 2>/dev/null || true
}

# --- Window Information Gathering -------------------------------------------
get_window_info() {
    yabai -m query --windows --window 2>/dev/null || echo '{}'
}

get_current_app() {
    local window_info="$1"
    local current_app
    current_app=$(echo "$window_info" | jq -r '.app // empty' 2>/dev/null)

    # Fallback methods if yabai fails
    if [[ -z "$current_app" || "$current_app" == "null" ]]; then
        current_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || echo "Desktop")
    fi

    # Handle special cases
    if [[ -z "$current_app" || "$current_app" == "null" ]]; then
        current_app="Desktop"
    fi

    echo "$current_app"
}

# --- Window State Functions -------------------------------------------------
update_window_state() {
    local window_info current_stack
    window_info=$(get_window_info)
    current_stack=$(echo "$window_info" | jq -r '.["stack-index"] // 0')

    if [[ $current_stack -gt 0 ]]; then
        local total_stack
        total_stack=$(yabai -m query --windows --window stack.last 2>/dev/null | jq -r '.["stack-index"] // 0')
        set_item_properties "$NAME" \
            icon="$YABAI_STACK" \
            icon.color="$RED" \
            label.drawing=on \
            label="$(printf "[%s/%s]" "$current_stack" "$total_stack")"
    else
        set_item_properties "$NAME" label.drawing=off
        local is_floating has_fullscreen has_parent
        is_floating=$(echo "$window_info" | jq -r '.["is-floating"] // false')
        has_fullscreen=$(echo "$window_info" | jq -r '.["has-fullscreen-zoom"] // false')
        has_parent=$(echo "$window_info" | jq -r '.["has-parent-zoom"] // false')

        if [ "$is_floating" = "true" ]; then
            set_item_properties "$NAME" icon="$YABAI_FLOAT" icon.color="$LIGHT_PURPLE"
        elif [ "$has_fullscreen" = "true" ]; then
            set_item_properties "$NAME" icon="$YABAI_FULLSCREEN_ZOOM" icon.color="$GREEN"
        elif [ "$has_parent" = "true" ]; then
            set_item_properties "$NAME" icon="$YABAI_PARENT_ZOOM" icon.color="$CYAN"
        else
            set_item_properties "$NAME" icon="$YABAI_GRID" icon.color="$LIGHT_GREEN"
        fi
    fi
}

# --- Front App Functions ----------------------------------------------------
update_focus_app() {
    local window_info app_name is_floating
    window_info=$(get_window_info)
    app_name=$(get_current_app "$window_info")
    is_floating=$(echo "$window_info" | jq -r '.["is-floating"] // false')

    # Set label and full visual style within the unified focus_app item
    if [ "$is_floating" = "true" ]; then
        set_item_properties focus_app \
            icon="$YABAI_FLOAT" \
            icon.color="$WHITE" \
            label="$app_name" \
            label.color="$WHITE" \
            background.color="$PRIMARY_PINK" \
            background.border_color="$LIGHT_RED" \
            background.border_width="$BORDER_THIN"
    else
        set_item_properties focus_app \
            icon="$YABAI_GRID" \
            icon.color="$BLACK" \
            label="$app_name" \
            label.color="$BLACK" \
            background.color="$PRIMARY_CYAN" \
            background.border_color="$LIGHT_WHITE" \
            background.border_width="$BORDER_THIN"
    fi
}

# --- Event Handler ----------------------------------------------------------
case "$SENDER" in
    # No hover behavior for focus_app
    "mouse.clicked")
        if [ "$NAME" = "focus_app" ]; then
            yabai -m window --toggle float 2>/dev/null || true
            update_focus_app
        fi
        ;;
    # Yabai / SketchyBar events
    "pf_window_focus"|"front_app_switched")
        if [[ "$NAME" == "window_state" || -z "$NAME" ]]; then
            update_window_state
        fi
        if [[ "$NAME" == "focus_app" || -z "$NAME" ]]; then
            update_focus_app
        fi
        ;;
    "forced")
        exit 0
        ;;
    *)
        # Default: update window info only
        if [[ -z "$NAME" ]]; then
            update_window_state
            update_focus_app
        elif [[ "$NAME" == "window_state" ]]; then
            update_window_state
        elif [[ "$NAME" == "focus_app" ]]; then
            update_focus_app
        fi
        ;;
esac
