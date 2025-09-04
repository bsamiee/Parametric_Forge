#!/bin/bash
# Title         : interaction-helpers.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/helpers/interaction-helpers.sh
# ----------------------------------------------------------------------------
# Minimal, agnostic utilities for SketchyBar interactions - no appearance logic
# shellcheck disable=SC1091

set -euo pipefail

# --- Safe SketchyBar Operations ---------------------------------------------
# Query item property with error handling
get_item_property() {
    local item="$1" property="$2"
    sketchybar --query "$item" 2>/dev/null | jq -r ".$property // empty" 2>/dev/null || echo ""
}

# Set item properties with error handling
set_item_properties() {
    local item="$1"; shift
    sketchybar --set "$item" "$@" 2>/dev/null || true
}

# Animated property changes
animate_item_properties() {
    local item="$1" curve="${2:-tanh}" duration="${3:-15}"; shift 3
    sketchybar --animate "$curve" "$duration" --set "$item" "$@" 2>/dev/null || true
}

# --- Generic Event Utilities -----------------------------------------------
# Dispatch custom event
dispatch_event() {
    local item="$1" event="$2"
    sketchybar --trigger "${item}_${event}" 2>/dev/null || true
}

# Generic mouse event router - items handle their own logic
handle_mouse_event() {
    local item_name="$1" event="$2"

    # Just dispatch to the item's script - let SketchyBar handle coordination
    case "$event" in
        "mouse.entered"|"mouse.exited"|"mouse.clicked")
            dispatch_event "$item_name" "$event"
            ;;
    esac
}

# --- Yabai Query Utilities -------------------------------------------------
# Generic yabai property query
query_yabai_property() {
    local type="$1" property="$2" selector="${3:-}"

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

# --- Main Entry Point -------------------------------------------------------
# Direct execution support for items that source this helper
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] && [[ -n "${NAME:-}" ]] && [[ -n "${SENDER:-}" ]]; then
    handle_mouse_event "$NAME" "$SENDER"
fi
