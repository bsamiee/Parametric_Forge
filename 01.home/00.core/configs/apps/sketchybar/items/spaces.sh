#!/bin/bash
# Title         : spaces.sh
# Author        : Bardia Samiee (adapted from FelixKratz)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/spaces.sh
# ----------------------------------------------------------------------------
# Dynamic space management with app icon integration

# shellcheck disable=SC2034,SC2206,SC2086  # SketchyBar config patterns

# --- Clean up existing spaces when recreating -------------------------------
sketchybar --remove '/space\..*/' 2>/dev/null || true
sketchybar --remove spaces 2>/dev/null || true
sketchybar --remove separator 2>/dev/null || true

CURRENT_SPACES=$(yabai -m query --spaces --display 2>/dev/null | jq -r '.[].index' | sort -n) # Get current spaces dynamically from yabai

# --- Dynamic Space Configuration --------------------------------------------
# Destroy space on right click, focus space on left click. New space by left clicking separator (>)
spaces=()
for space in $CURRENT_SPACES; do
  space_config=(
    associated_space=$space
    icon=$space
    icon.padding_left=10
    icon.padding_right=15
    padding_left=2
    padding_right=2
    label.padding_right=20
    icon.highlight_color=$RED
    label.font="sketchybar-app-font:Regular:16.0"
    label.background.height=26
    label.background.drawing=on
    label.background.color=$FAINT_DARK_GREY
    label.background.corner_radius=8
    label.drawing=off
    script="$PLUGIN_DIR/space.sh"
  )

  sketchybar --add space space.$space left    \
             --set space.$space "${space_config[@]}" \
             --subscribe space.$space mouse.clicked
done

# --- Space Grouping ---------------------------------------------------------
spaces_bracket=(
  background.color=$LIGHT_DARK_GREY
  background.border_color=$DARK_GREY
  background.border_width=2
  background.drawing=on
)

separator=(
  icon=􀆊
  icon.font="GeistMono Nerd Font:Heavy:16.0"
  padding_left=15
  padding_right=15
  label.drawing=off
  associated_display=active
  click_script='yabai -m space --create && sketchybar --trigger space_change'
  icon.color=$WHITE
)

sketchybar --add bracket spaces '/space\..*/'   \
           --set spaces "${spaces_bracket[@]}"  \
                                                \
           --add item separator left            \
           --set separator "${separator[@]}"

# --- Trigger app icon updates -----------------------------------------------
sketchybar --trigger windows_on_spaces
