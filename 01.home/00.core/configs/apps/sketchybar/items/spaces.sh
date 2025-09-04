#!/bin/bash
# Title         : spaces.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/spaces.sh
# ----------------------------------------------------------------------------
# Dynamic space generation with app icon integration
# shellcheck disable=SC2034 # Used for potential future array operations
# shellcheck disable=SC1091
# shellcheck disable=SC2086 # BRACKET_ITEMS needs word splitting for sketchybar args

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/constants.sh"

# --- Space Management -------------------------------------------------------
# Check if yabai is available, fallback to default spaces if not
if command -v yabai >/dev/null 2>&1 && yabai -m query --spaces >/dev/null 2>&1; then
  CURRENT_SPACES=$(yabai -m query --spaces --display 2>/dev/null | jq -r '.[].index' | sort -n)
else
  # Fallback: create 3 default spaces when yabai is unavailable
  CURRENT_SPACES="1 2 3"
fi

EXISTING_SPACES=$(sketchybar --query bar 2>/dev/null | jq -r '.items[]' | /usr/bin/grep '^space\.' | /usr/bin/sed 's/space\.//' 2>/dev/null || echo "")

# --- Space Creation ---------------------------------------------------------
for space in $CURRENT_SPACES; do
  if ! echo "$EXISTING_SPACES" | grep -q "^$space$"; then
    space_config=(
      associated_space="$space"
      icon="$space"
      icon.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM"
      icon.color="$WHITE"
      icon.padding_left="$PADDINGS_XLARGE"
      icon.padding_right="$PADDINGS_XLARGE"
      icon.highlight_color="$CYAN"

      padding_left="$PADDINGS_NONE"
      padding_right="$PADDINGS_NONE"

      label.padding_left="$PADDINGS_MEDIUM"
      label.padding_right="$PADDINGS_XXLARGE"
      label.font="$APP_FONT"
      label.color="$WHITE"
      label.y_offset=-2
      label.drawing=off

      background.drawing=off

      label.background.drawing=off

      script="$HOME/.config/sketchybar/plugins/space.sh"
    )

    # Create space with subscription
    sketchybar --add space space."$space" left \
      --set space."$space" "${space_config[@]}" \
      --subscribe space."$space" mouse.clicked mouse.entered mouse.exited
  fi
done

# --- Space Removal ----------------------------------------------------------
if [ -n "$EXISTING_SPACES" ]; then
  for existing_space in $EXISTING_SPACES; do
    if ! echo "$CURRENT_SPACES" | grep -q "^$existing_space$"; then
      sketchybar --remove space."$existing_space" 2>/dev/null || true
    fi
  done
fi

# --- Add Space Button -------------------------------------------------------
add_space_button=(
  icon="$ADD_SPACE"
  icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM"
  icon.color="$PINK"
  icon.padding_left="$PADDINGS_XLARGE"
  icon.padding_right="$PADDINGS_XLARGE"
  padding_left="$PADDINGS_NONE"
  padding_right="$PADDINGS_NONE"
  label.drawing=off
  associated_display=active
  click_script='yabai -m space --create && sketchybar --trigger space_change'
  background.drawing=off
)

sketchybar --query add_space >/dev/null 2>&1 && sketchybar --remove add_space
sketchybar --add item add_space left \
  --set add_space "${add_space_button[@]}" \
  script="$HOME/.config/sketchybar/plugins/space.sh" \
  --subscribe add_space mouse.clicked mouse.entered mouse.exited

# --- Spaces Bracket ---------------------------------------------------------
spaces_bracket=(
  background.color="$TRANSPARENT"
  background.border_color="$LIGHT_WHITE"
  background.border_width="$BORDER_THIN"
  background.corner_radius="$RADIUS_LARGE"
  background.height="$HEIGHT_ITEM"
  background.padding_left="$PADDINGS_LARGE"
  background.padding_right="$PADDINGS_MEDIUM"
  background.drawing=on
)

sketchybar --query spaces >/dev/null 2>&1 && sketchybar --remove spaces
BRACKET_ITEMS=$(echo "$CURRENT_SPACES" | /usr/bin/sed 's/^/space./' | tr '\n' ' ')
sketchybar --add bracket spaces $BRACKET_ITEMS add_space \
  --set spaces "${spaces_bracket[@]}"

# --- Positioning ------------------------------------------------------------
LEFTMOST_SPACE=$(echo "$CURRENT_SPACES" | head -n1)
RIGHTMOST_SPACE=$(echo "$CURRENT_SPACES" | tail -n1)

positioning_args=()
if sketchybar --query yabai >/dev/null 2>&1 && [ -n "$LEFTMOST_SPACE" ]; then
  positioning_args+=(--move yabai before space."$LEFTMOST_SPACE")
fi
if [ -n "$RIGHTMOST_SPACE" ]; then
  positioning_args+=(--move add_space after space."$RIGHTMOST_SPACE")
fi

if [ ${#positioning_args[@]} -gt 0 ]; then
  sketchybar "${positioning_args[@]}" 2>/dev/null || true
fi


# --- Updates ----------------------------------------------------------------
sketchybar --trigger windows_on_spaces
