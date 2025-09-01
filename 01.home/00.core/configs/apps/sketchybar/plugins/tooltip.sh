#!/bin/bash
# Title         : tooltip.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/tooltip.sh
# ----------------------------------------------------------------------------
# Universal hover tooltip handler for SketchyBar items
# shellcheck disable=SC1091

# --- Load Configuration ------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"

# --- Configuration -----------------------------------------------------------
TOOLTIP_DELAY=0.3  # Seconds to wait before showing tooltip
TOOLTIP_ITEM="${NAME}_tooltip"

# --- Show Tooltip Function --------------------------------------------------
show_tooltip() {
  local item_name="$1"
  
  # Generate tooltip content using the helper
  local tooltip_content
  tooltip_content=$("$HOME/.config/sketchybar/helpers/tooltip-generator.sh" "$item_name")
  
  if [ -n "$tooltip_content" ]; then
    # Create/update tooltip item in the popup
    sketchybar --add item "$TOOLTIP_ITEM" "popup.$item_name" \
      --set "$TOOLTIP_ITEM" \
      icon.drawing=off \
      label="$tooltip_content" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
      label.color="$WHITE" \
      label.padding_left="$PADDINGS" \
      label.padding_right="$PADDINGS" \
      background.color="$DARK_GREY" \
      background.border_color="$GREY" \
      background.border_width="$BORDER_THIN" \
      background.corner_radius=6 \
      background.padding_left="$PADDINGS" \
      background.padding_right="$PADDINGS" \
      background.height=26
    
    # Show the popup with slight delay for natural feel (background process)
    (sleep "$TOOLTIP_DELAY" && sketchybar --set "$item_name" popup.drawing=on) &
  fi
}

# --- Hide Tooltip Function --------------------------------------------------
hide_tooltip() {
  local item_name="$1"
  
  # Hide the popup
  sketchybar --set "$item_name" popup.drawing=off
  
  # Clean up tooltip item
  sketchybar --remove "$TOOLTIP_ITEM" 2>/dev/null || true
}

# --- Event Handler ----------------------------------------------------------
case "$SENDER" in
  "mouse.entered")
    show_tooltip "$NAME"
    ;;
  "mouse.exited")
    hide_tooltip "$NAME"
    ;;
esac