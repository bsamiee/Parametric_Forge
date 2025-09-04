#!/bin/bash
# Title         : interaction-helpers.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/helpers/interaction-helpers.sh
# ----------------------------------------------------------------------------
# Unified interaction system providing visual feedback, animations, state queries, and toggle logic
# shellcheck disable=SC1091

set -euo pipefail

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"

# --- Feedback States --------------------------------------------------------
FEEDBACK_HOVER_BG="$LIGHT_BLACK"
FEEDBACK_HOVER_LABEL="$PRIMARY_CYAN"
FEEDBACK_HOVER_BORDER="$PRIMARY_ORANGE"
FEEDBACK_CLICK_BG="$LIGHT_PURPLE"
FEEDBACK_CLICK_LABEL="$PRIMARY_CYAN"
FEEDBACK_DEFAULT_BG="$TRANSPARENT"
FEEDBACK_DEFAULT_LABEL="$WHITE"
FEEDBACK_DEFAULT_BORDER="$TRANSPARENT"

# --- Apply Visual State -----------------------------------------------------
apply_visual_state() {
    local item_name="$1"
    local state="$2"

    case "$state" in
        "hover")
            sketchybar --set "$item_name" \
                background.color="$FEEDBACK_HOVER_BG" \
                background.border_color="$FEEDBACK_HOVER_BORDER" \
                background.border_width="$BORDER_THIN" \
                background.border_radius="$RADIUS_LARGE" \
                label.color="$FEEDBACK_HOVER_LABEL" \
                background.drawing=on
            ;;
        "click")
            # Brief visual flash without blocking
            sketchybar --set "$item_name" \
                background.color="$FEEDBACK_CLICK_BG" \
                label.color="$FEEDBACK_CLICK_LABEL" \
                background.drawing=on
            # Non-blocking reset using animation
            sketchybar --animate sin 5 --set "$item_name" \
                background.color="$FEEDBACK_DEFAULT_BG" \
                background.border_color="$FEEDBACK_DEFAULT_BORDER" \
                background.border_width="$BORDER_NONE" \
                label.color="$FEEDBACK_DEFAULT_LABEL" \
                background.drawing=off 2>/dev/null || true
            ;;
        "default"|*)
            sketchybar --set "$item_name" \
                background.color="$FEEDBACK_DEFAULT_BG" \
                background.border_color="$FEEDBACK_DEFAULT_BORDER" \
                background.border_width="$BORDER_NONE" \
                label.color="$FEEDBACK_DEFAULT_LABEL" \
                background.drawing=off
            ;;
    esac
}

# --- Mouse Events -----------------------------------------------------------
handle_mouse_event() {
    local item_name="$1"
    local event="$2"

    case "$event" in
        "mouse.entered")
            apply_visual_state "$item_name" "hover"
            ;;
        "mouse.exited"|"mouse.exited.global")
            # Handle both regular and global exit events (workaround for SketchyBar bug #613)
            apply_visual_state "$item_name" "default"
            ;;
        "mouse.clicked")
            apply_visual_state "$item_name" "click"
            ;;
    esac
}

# --- Background Hover Effects -----------------------------------------------
apply_icon_background_hover() {
    local item_name="$1"
    local hover_color="$2"
    local text_color="${3:-$WHITE}"

    apply_instant_change "$item_name" \
        icon.color="$text_color" \
        background.drawing=on \
        background.color="$hover_color" \
        background.border_radius="$RADIUS_LARGE" \
        background.height="$HEIGHT_ITEM" \
        background.padding_left="$PADDINGS_SMALL" \
        background.padding_right="$PADDINGS_SMALL"
}

remove_icon_background_hover() {
    local item_name="$1"
    local default_color="$2"

    apply_instant_change "$item_name" \
        icon.color="$default_color" \
        background.drawing=off
}

handle_special_hover_effects() {
    local item_name="$1"
    local event="$2"
    local item_type="${3:-default}"

    case "$item_type" in
        "add_space")
            case "$event" in
                "mouse.entered")
                    apply_icon_background_hover "$item_name" "$PINK" "$WHITE"
                    ;;
                "mouse.exited")
                    remove_icon_background_hover "$item_name" "$PINK"
                    ;;
            esac
            ;;
        *)
            # Use standard visual feedback for unknown types
            handle_mouse_event "$item_name" "$event"
            ;;
    esac
}

# --- Animation Effects ------------------------------------------------------
apply_smooth_animation() {
    local item_name="$1"
    local duration="${2:-15}"  # Default to 15, allow override
    shift 2
    local properties=("$@")

    sketchybar --animate tanh "$duration" --set "$item_name" "${properties[@]}" 2>/dev/null || true
}

apply_instant_change() {
    local item_name="$1"
    shift
    local properties=("$@")

    sketchybar --set "$item_name" "${properties[@]}" 2>/dev/null || true
}

# --- State Query Helpers ----------------------------------------------------
query_yabai() {
    local type="$1"      # "windows" or "spaces"
    local property="$2"
    local selector="${3:-}"

    case "$type" in
        "windows")
            if [ -n "$selector" ]; then
                yabai -m query --windows --window "$selector" 2>/dev/null | jq -r ".$property // empty" 2>/dev/null || echo ""
            else
                yabai -m query --windows --window 2>/dev/null | jq -r ".$property // empty" 2>/dev/null || echo ""
            fi
            ;;
        "spaces")
            if [ -n "$selector" ]; then
                yabai -m query --spaces --space "$selector" 2>/dev/null | jq -r ".$property // empty" 2>/dev/null || echo ""
            else
                yabai -m query --spaces --display 2>/dev/null | jq -r ".[] | select(.\"has-focus\" == true) | .$property // empty" 2>/dev/null || echo ""
            fi
            ;;
    esac
}

check_window_state() {
    local state="$1"  # floating, fullscreen-zoom, parent-zoom, stack-index
    local window_value

    case "$state" in
        "floating")
            window_value=$(query_yabai "windows" "is-floating")
            [[ "$window_value" == "true" ]]
            ;;
        "fullscreen")
            window_value=$(query_yabai "windows" "has-fullscreen-zoom") 
            [[ "$window_value" == "true" ]]
            ;;
        "parent_zoom")
            window_value=$(query_yabai "windows" "has-parent-zoom")
            [[ "$window_value" == "true" ]]
            ;;
        "stacked")
            window_value=$(query_yabai "windows" "stack-index")
            [[ -n "$window_value" && "$window_value" -gt 0 ]]
            ;;
        *)
            false
            ;;
    esac
}

# --- Toggle State Management ------------------------------------------------
get_item_state() {
    local item_name="$1"
    local property="${2:-icon.value}"

    sketchybar --query "$item_name" 2>/dev/null | jq -r ".$property // \"\"" 2>/dev/null || echo ""
}

handle_toggle_state() {
    local item_name="$1"
    local collapsed_icon="$2"
    local expanded_icon="$3"
    local controls_array=("${@:4}")

    local current_icon
    current_icon=$(get_item_state "$item_name" "icon.value")

    if [[ "$current_icon" == "$expanded_icon" ]]; then
        # Currently expanded - collapse
        toggle_items_visibility "off" "${controls_array[@]}"
        apply_smooth_animation "$item_name" 15 \
            icon="$collapsed_icon" \
            icon.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_LARGE" \
            icon.padding_left="$PADDINGS_LARGE" \
            icon.padding_right="$PADDINGS_LARGE" \
            icon.y_offset=0
    else
        # Currently collapsed - expand
        toggle_items_visibility "on" "${controls_array[@]}"
        apply_smooth_animation "$item_name" 15 \
            icon="$expanded_icon" \
            icon.font="$TEXT_FONT:$BOLD_WEIGHT:$SIZE_LARGE" \
            icon.padding_left="$PADDINGS_NONE" \
            icon.padding_right="$PADDINGS_NONE" \
            icon.y_offset=2
    fi
}

toggle_items_visibility() {
    local state="$1"
    shift
    local items=("$@")

    for item in "${items[@]}"; do
        local processed_item
        processed_item=${item//__/ }
        apply_smooth_animation "$processed_item" 15 drawing="$state"
    done

    if [ "$state" = "on" ]; then
        sketchybar --trigger control_center_update 2>/dev/null || true
    fi
}

# --- Main Entry Point -------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Called directly - handle event for $NAME item
    handle_mouse_event "$NAME" "$SENDER"
fi
