#!/bin/bash
# Title         : window_state.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/window_state.sh
# ----------------------------------------------------------------------------
# Unified window management: state visualization and front app display
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Window Information Gathering ------------------------------------------
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

# --- Window State Functions -----------------------------------------------
update_window_state() {
    local window_info current_stack
    window_info=$(get_window_info)
    current_stack=$(echo "$window_info" | jq -r '.["stack-index"] // 0')

    local args=()

    if [[ $current_stack -gt 0 ]]; then
        local total_stack
        total_stack=$(yabai -m query --windows --window stack.last 2>/dev/null | jq -r '.["stack-index"] // 0')
        args+=(--set "$NAME"
            icon="$YABAI_STACK"
            icon.color="$RED"
            label.drawing=on
            label="$(printf "[%s/%s]" "$current_stack" "$total_stack")")
        yabai -m config active_window_border_color "$RED" 2>/dev/null &
    else
        args+=(--set "$NAME" label.drawing=off)
        local is_floating has_fullscreen has_parent
        is_floating=$(echo "$window_info" | jq -r '.["is-floating"] // false')
        has_fullscreen=$(echo "$window_info" | jq -r '.["has-fullscreen-zoom"] // false')
        has_parent=$(echo "$window_info" | jq -r '.["has-parent-zoom"] // false')

        if [ "$is_floating" = "true" ]; then
            args+=(--set "$NAME" icon="$YABAI_FLOAT" icon.color="$PURPLE")
            yabai -m config active_window_border_color "$PURPLE" 2>/dev/null &
        elif [ "$has_fullscreen" = "true" ]; then
            args+=(--set "$NAME" icon="$YABAI_FULLSCREEN_ZOOM" icon.color="$GREEN")
            yabai -m config active_window_border_color "$GREEN" 2>/dev/null &
        elif [ "$has_parent" = "true" ]; then
            args+=(--set "$NAME" icon="$YABAI_PARENT_ZOOM" icon.color="$CYAN")
            yabai -m config active_window_border_color "$CYAN" 2>/dev/null &
        else
            args+=(--set "$NAME" icon="$YABAI_GRID" icon.color="$ORANGE")
            yabai -m config active_window_border_color "$WHITE" 2>/dev/null &
        fi
    fi

    if ! sketchybar -m "${args[@]}" 2>/dev/null; then
        echo "Warning: Failed to update window state for $NAME" >&2
    fi
}

# --- Front App Functions ------------------------------------------------
update_front_app() {
    local window_info app_name is_floating
    window_info=$(get_window_info)
    app_name=$(get_current_app "$window_info")
    is_floating=$(echo "$window_info" | jq -r '.["is-floating"] // false')

    if [ "$is_floating" = "true" ]; then
        sketchybar --set front_app icon="$YABAI_FLOAT" icon.color="$PURPLE" label="$app_name"
    else
        sketchybar --set front_app icon="$YABAI_GRID" icon.color="$ORANGE" label="$app_name"
    fi
}

# --- Mouse Handlers -------------------------------------------------------
handle_window_state_click() {
    yabai -m window --toggle float 2>/dev/null || true
    update_window_state
}

handle_front_app_mouse() {
    case "$SENDER" in
        "mouse.entered")
            apply_visual_state "front_app" "hover"
            ;;
        "mouse.exited")
            apply_visual_state "front_app" "default"
            ;;
        "mouse.clicked")
            apply_visual_state "front_app" "click"
            # Toggle float state
            if command -v yabai >/dev/null 2>&1; then
                yabai -m window --toggle float 2>/dev/null
                sleep 0.1
                update_front_app
            fi
            ;;
    esac
}

# --- Event Handler --------------------------------------------------------
case "$SENDER" in
    "mouse.clicked")
        if [[ "$NAME" == "window_state" ]]; then
            handle_window_state_click
        elif [[ "$NAME" == "front_app" ]]; then
            handle_front_app_mouse
        fi
        ;;
    "mouse.entered"|"mouse.exited")
        if [[ "$NAME" == "front_app" ]]; then
            handle_front_app_mouse
        fi
        ;;
    "window_focus")
        if [[ "$NAME" == "window_state" || -z "$NAME" ]]; then
            update_window_state
        fi
        if [[ "$NAME" == "front_app" || -z "$NAME" ]]; then
            update_front_app
        fi
        ;;
    "forced")
        exit 0
        ;;
    *)
        # Default: update window info only
        if [[ -z "$NAME" ]]; then
            update_window_state
            update_front_app
        elif [[ "$NAME" == "window_state" ]]; then
            update_window_state
        elif [[ "$NAME" == "front_app" ]]; then
            update_front_app
        fi
        ;;
esac
