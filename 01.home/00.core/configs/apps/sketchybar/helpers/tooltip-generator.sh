#!/bin/bash
# Title         : tooltip-generator.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/helpers/tooltip-generator.sh
# ----------------------------------------------------------------------------
# Dynamic tooltip content generator for SketchyBar items
# shellcheck disable=SC1091

# --- Generate Tooltip Content -----------------------------------------------
generate_tooltip() {
  local item_name="$1"

  case "$item_name" in
    "yabai")
      generate_yabai_tooltip
      ;;
    space.*)
      generate_space_tooltip "$item_name"
      ;;
    *)
      # Default tooltip for unknown items
      echo "Unknown item: $item_name"
      ;;
  esac
}

# --- Yabai Tooltip Generator ------------------------------------------------
generate_yabai_tooltip() {
  # Get current window information
  local window_info
  window_info=$(yabai -m query --windows --window 2>/dev/null)

  if [ -n "$window_info" ]; then
    local app_name
    local is_floating
    local has_fullscreen_zoom
    local has_parent_zoom

    app_name=$(echo "$window_info" | jq -r '.app // "Desktop"')
    is_floating=$(echo "$window_info" | jq -r '.["is-floating"]')
    has_fullscreen_zoom=$(echo "$window_info" | jq -r '.["has-fullscreen-zoom"]')
    has_parent_zoom=$(echo "$window_info" | jq -r '.["has-parent-zoom"]')

    # Determine current state
    local state="BSP"
    if [ "$is_floating" = "true" ]; then
      state="Float"
    elif [ "$has_fullscreen_zoom" = "true" ]; then
      state="Fullscreen"
    elif [ "$has_parent_zoom" = "true" ]; then
      state="Parent Zoom"
    fi

    # Format tooltip content
    printf "Yabai: %s • %s\n" "$state" "$app_name"
    printf "Click: Toggle float • Right: Menu"
  else
    printf "Yabai: No window focused\n"
    printf "Click: Toggle float • Right: Menu"
  fi
}

# --- Space Tooltip Generator ------------------------------------------------
generate_space_tooltip() {
  local item_name="$1"
  local space_id
  space_id=$(echo "$item_name" | cut -d'.' -f2)

  # Get space information
  local space_info
  space_info=$(yabai -m query --spaces --space "$space_id" 2>/dev/null)

  if [ -n "$space_info" ]; then
    local is_focused
    local windows_count

    is_focused=$(echo "$space_info" | jq -r '.["has-focus"]')
    windows_count=$(echo "$space_info" | jq -r '.windows | length')

    local status="Active"
    [ "$is_focused" = "false" ] && status="Inactive"

    printf "Space %s • %s\n" "$space_id" "$status"
    printf "%d windows • Click: Focus space" "$windows_count"
  else
    printf "Space %s\n" "$space_id"
    printf "Click: Focus space"
  fi
}

# --- Main Entry Point -------------------------------------------------------
if [ $# -eq 0 ]; then
  echo "Usage: tooltip-generator.sh <item_name>"
  exit 1
fi

generate_tooltip "$1"