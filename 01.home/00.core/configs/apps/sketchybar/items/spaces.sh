#!/bin/bash
# Title         : spaces.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/spaces.sh
# ----------------------------------------------------------------------------
# Unified space management: creation, dynamic updates, and yabai integration
# shellcheck disable=SC2034 # Used for potential future array operations
# shellcheck disable=SC1091
# shellcheck disable=SC2086 # BRACKET_ITEMS needs word splitting for sketchybar args

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/plugins/icon_map.sh"

# --- Space Discovery --------------------------------------------------------
discover_spaces() {
  if command -v yabai >/dev/null 2>&1 && yabai -m query --spaces >/dev/null 2>&1; then
    if command -v jq >/dev/null 2>&1; then
      # Query all spaces across all displays and list their mission-control indices
      yabai -m query --spaces 2>/dev/null | jq -r '.[].index' | sort -n || echo "1 2 3"
    else
      # jq not available; fall back to a sane default
      echo "1 2 3"
    fi
  else
    # Fallback: create 3 default spaces when yabai is unavailable
    echo "1 2 3"
  fi
}

get_existing_spaces() {
  sketchybar --query bar 2>/dev/null | jq -r '.items[]' | /usr/bin/grep '^space\.' | /usr/bin/sed 's/space\.//' 2>/dev/null || echo ""
}

# --- Space Creation and Management ------------------------------------------
create_spaces() {
  local current_spaces existing_spaces
  current_spaces=$(discover_spaces)
  existing_spaces=$(get_existing_spaces)

  # Create missing spaces
  for space in $current_spaces; do
    if ! echo "$existing_spaces" | grep -q "^$space$"; then
      space_config=(
        space="$space"
        icon="$space"
        icon.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM"
        icon.padding_left="$PADDINGS_XLARGE"
        icon.padding_right="$PADDINGS_XLARGE"

        padding_left="$PADDINGS_NONE"
        padding_right="$PADDINGS_NONE"

        label.padding_left="$PADDINGS_SMALL"
        label.padding_right="$PADDINGS_XXLARGE"
        label.font="$APP_FONT"
        label.y_offset=-2

        # Focus space on left click (explicit to avoid relying on defaults)
        click_script="yabai -m space --focus $space"

        script="$HOME/.config/sketchybar/plugins/space.sh"
      )

      # Create space with comprehensive event subscription
      sketchybar --add space space."$space" left \
        --set space."$space" "${space_config[@]}" \
        --subscribe space."$space" mouse.clicked mouse.entered mouse.exited space_change pf_space_change space_windows_change
    fi
  done

  # Remove obsolete spaces
  if [ -n "$existing_spaces" ]; then
    for existing_space in $existing_spaces; do
      if ! echo "$current_spaces" | grep -q "^$existing_space$"; then
        sketchybar --remove space."$existing_space" 2>/dev/null || true
      fi
    done
  fi

  echo "$current_spaces"
}

# --- Add Space Button Management --------------------------------------------
create_add_space_button() {
  add_space_button=(
    icon="$ADD_SPACE"
    icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM"
    icon.color="$PINK"
    icon.padding_left="$PADDINGS_LARGE"
    icon.padding_right="$PADDINGS_LARGE"
    padding_left="$PADDINGS_NONE"
    padding_right="$PADDINGS_SMALL"
    label.drawing=off
    display=active
    # Ensure Homebrew paths are available for click execution regardless of service env
    click_script='PATH=/opt/homebrew/bin:/usr/local/bin:$PATH yabai -m space --create && sketchybar --trigger pf_space_change'
    background.drawing=off
    background.height="$((HEIGHT_ITEM - 2))"
    background.corner_radius="$RADIUS_LARGE"
    background.padding_left="$PADDINGS_NONE"
    background.padding_right="$PADDINGS_NONE"
    script="$HOME/.config/sketchybar/items/spaces.sh"
  )

  sketchybar --query add_space >/dev/null 2>&1 && sketchybar --remove add_space
  sketchybar --add item add_space left \
    --set add_space "${add_space_button[@]}" \
    --subscribe add_space mouse.entered mouse.exited
}

# --- Spaces Bracket Management ----------------------------------------------
create_spaces_bracket() {
  local current_spaces="$1"

  # Compare with last snapshot to avoid unnecessary bracket churn
  local snapshot_file="/tmp/sketchybar_spaces_snapshot"
  local last_snapshot=""
  [[ -f "$snapshot_file" ]] && last_snapshot=$(cat "$snapshot_file" 2>/dev/null || true)

  if [[ "$current_spaces" != "$last_snapshot" ]]; then
    spaces_bracket=(
      background.color="$TRANSPARENT"
      background.border_color="$LIGHT_WHITE"
      background.border_width="$BORDER_THIN"
      background.corner_radius="$RADIUS_LARGE"
      background.height="$HEIGHT_ITEM"
      background.padding_left="$PADDINGS_MEDIUM"
      background.padding_right="$PADDINGS_MEDIUM"
      background.drawing=on
    )

    sketchybar --query spaces >/dev/null 2>&1 && sketchybar --remove spaces
    BRACKET_ITEMS=$(echo "$current_spaces" | /usr/bin/sed 's/^/space./' | tr '\n' ' ')
    sketchybar --add bracket spaces $BRACKET_ITEMS add_space \
      --set spaces "${spaces_bracket[@]}"

    echo "$current_spaces" > "$snapshot_file"
  fi
}

# --- Event Handler ----------------------------------------------------------
handle_events() {
  case "$SENDER" in
    "mouse.entered")
      [ "$NAME" = "add_space" ] && sketchybar --set add_space \
        icon.color="$WHITE" \
        background.drawing=on \
        background.color="$PINK" \
        background.border_color="$RED" \
        background.border_width="$BORDER_THIN"
      ;;
    "mouse.exited")
      [ "$NAME" = "add_space" ] && sketchybar --set add_space \
        icon.color="$PINK" \
        background.drawing=off
      ;;
    "mouse.clicked")
      # click_script handles the actual space creation
      return 0
      ;;
    "space_change"|"pf_space_change"|"space_windows_change")
      # Space discovery and layout update
      CURRENT_SPACES=$(create_spaces)
      create_add_space_button
      create_spaces_bracket "$CURRENT_SPACES"

      # Position items - clean layout without separator
      LEFTMOST_SPACE=$(echo "$CURRENT_SPACES" | head -n1)
      RIGHTMOST_SPACE=$(echo "$CURRENT_SPACES" | tail -n1)

      if [ -n "$LEFTMOST_SPACE" ]; then
        # Position spaces after logo (guaranteed to exist) for clean left-side ordering
        positioning_args=(
          --move space."$LEFTMOST_SPACE" after logo
          --move add_space after space."$RIGHTMOST_SPACE"
          --move separator_spaces after add_space
          --move focus_app after separator_spaces
        )
        sketchybar "${positioning_args[@]}" 2>/dev/null || true
      fi
      ;;
  esac
}

# --- Main Entry Point -------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ -n "${SENDER:-}" ]]; then
  handle_events
fi
