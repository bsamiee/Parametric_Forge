#!/bin/bash
# Title         : spaces.sh
# Author        : Bardia Samiee (adapted from FelixKratz)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/spaces.sh
# ----------------------------------------------------------------------------
# Dynamic space generation with app icon integration
# shellcheck disable=SC2034 # Used for potential future array operations
# shellcheck disable=SC1091

# --- Load Configuration Variables -------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/constants.sh"

# --- Atomic Space Management (No Destruction) -------------------------------
CURRENT_SPACES=$(yabai -m query --spaces --display 2>/dev/null | jq -r '.[].index' | sort -n)
EXISTING_SPACES=$(sketchybar --query bar 2>/dev/null | jq -r '.items[]' | grep '^space\.' | sed 's/space\.//' 2>/dev/null || echo "")

# --- Add New Spaces Only -------------------------------------------------
for space in $CURRENT_SPACES; do
  if ! echo "$EXISTING_SPACES" | grep -q "^$space$"; then
    space_config=(
      associated_space="$space"
      icon="$space"
      icon.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM"
      icon.color="$WHITE"
      icon.padding_left=8
      icon.padding_right=8
      padding_left="$PADDINGS"
      padding_right="$PADDINGS"
      label.padding_left=6
      label.padding_right=6
      icon.highlight_color="$CYAN"
      icon.background.height=2
      icon.background.y_offset=-14
      icon.background.color="$TRANSPARENT"
      icon.background.corner_radius=1
      icon.background.drawing=on
      label.font="$APP_FONT"
      label.background.drawing=off
      label.drawing=off
      script="$HOME/.config/sketchybar/plugins/space.sh"
    )

    sketchybar --add space space."$space" left  \
      --set space."$space" "${space_config[@]}" \
      --subscribe space."$space" mouse.clicked mouse.entered mouse.exited
  fi
done

# --- Remove Obsolete Spaces ----------------------------------------------
if [ -n "$EXISTING_SPACES" ]; then
  for existing_space in $EXISTING_SPACES; do
    if ! echo "$CURRENT_SPACES" | grep -q "^$existing_space$"; then
      sketchybar --remove space."$existing_space" 2>/dev/null || true
    fi
  done
fi

# --- Ensure Bracket & Separator Exist ------------------------------------
if ! sketchybar --query spaces >/dev/null 2>&1; then
  spaces_bracket=(
    background.color="$FAINT_DARK_GREY"
    background.border_color="$GREY"
    background.border_width="$BORDER_THIN"
    background.corner_radius=8
    background.height=28
    background.drawing=on
  )

  sketchybar --add bracket spaces '/space\..*/' \
    --set spaces "${spaces_bracket[@]}"
fi

if ! sketchybar --query separator >/dev/null 2>&1; then
  separator=(
    icon="$SEPARATOR"
    icon.font="$SYMBOL_FONT:$BOLD_WEIGHT:$SIZE_LARGE"
    padding_left=15
    padding_right=15
    label.drawing=off
    associated_display=active
    click_script='yabai -m space --create && sketchybar --trigger space_change'
    icon.color="$WHITE"
  )

  sketchybar --add item separator left \
    --set separator "${separator[@]}"
fi

# --- Trigger app icon updates -----------------------------------------------
sketchybar --trigger windows_on_spaces
