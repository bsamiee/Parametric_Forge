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
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Space Discovery --------------------------------------------------------
discover_spaces() {
  if command -v yabai >/dev/null 2>&1 && yabai -m query --spaces >/dev/null 2>&1; then
    yabai -m query --spaces --display 2>/dev/null | jq -r '.[].index' | sort -n
  else
    # Fallback: create 3 default spaces when yabai is unavailable
    echo "1 2 3"
  fi
}

get_existing_spaces() {
  sketchybar --query bar 2>/dev/null | jq -r '.items[]' | /usr/bin/grep '^space\.' | /usr/bin/sed 's/space\.//' 2>/dev/null || echo ""
}

# --- Dynamic Space Updates --------------------------------------------------
update_space_icons() {
  local space_data all_windows
  space_data=$(yabai -m query --spaces --display 2>/dev/null || echo '[]')
  all_windows=$(yabai -m query --windows 2>/dev/null || echo '[]')

  local active_space current_spaces
  active_space=$(echo "$space_data" | jq -r '.[] | select(.["has-focus"] == true) | .index // ""')
  current_spaces=$(echo "$space_data" | jq -r '.[].index // empty')

  local args=()
  for space in $current_spaces; do
    local icon_strip=" "

    # Get apps for this space with filtering
    local apps
    apps=$(echo "$all_windows" | jq -r --arg space "$space" '
      .[] | select(
        .space == ($space | tonumber) and
        .["has-ax-reference"] == true and
        .["is-minimized"] == false and
        .["is-hidden"] == false and
        (.layer // "") == "normal"
      ) | .app // empty' | sort -u)

    # Build icon strip
    if [ -n "$apps" ]; then
      while IFS= read -r app; do
        [ -n "$app" ] && icon_strip+=" $(get_app_icon "$app")"
      done <<<"$apps"
    fi

    # Apply nested bracket styling with proper color logic
    if [ "$space" = "$active_space" ]; then
      args+=(--set "space.$space"
        label="$icon_strip"
        label.drawing=on
        label.color="$BLACK"
        label.background.color="$FAINT_CYAN"
        icon.color="$BLACK"
        background.drawing=on
        background.color="$PRIMARY_CYAN"
        background.border_color="$CYAN"
        background.border_width="$BORDER_THIN")
    else
      # Check if space is empty for red indicator
      if [ -z "$apps" ] || [ "$icon_strip" = " " ]; then
        args+=(--set "space.$space"
          label="$icon_strip"
          label.drawing=on
          label.color="$WHITE"
          label.background.color="$TRANSPARENT"
          icon.color="$PRIMARY_RED"
          background.drawing=off
          background.color="$TRANSPARENT"
          background.border_color="$TRANSPARENT"
          background.border_width=0)
      else
        args+=(--set "space.$space"
          label="$icon_strip"
          label.drawing=on
          label.color="$WHITE"
          label.background.color="$TRANSPARENT"
          icon.color="$WHITE"
          background.drawing=off
          background.color="$TRANSPARENT"
          background.border_color="$TRANSPARENT"
          background.border_width=0)
      fi
    fi
  done

  if [ ${#args[@]} -gt 0 ] && ! sketchybar -m "${args[@]}" 2>/dev/null; then
    echo "Warning: Failed to update space icons" >&2
  fi
}

# --- Space Creation and Management -------------------------------------------
create_spaces() {
  local current_spaces existing_spaces
  current_spaces=$(discover_spaces)
  existing_spaces=$(get_existing_spaces)

  # Create missing spaces
  for space in $current_spaces; do
    if ! echo "$existing_spaces" | grep -q "^$space$"; then
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

        script="$HOME/.config/sketchybar/items/spaces.sh"
        click_script="yabai -m space --focus $space 2>/dev/null || true"
      )

      # Create space with subscription
      sketchybar --add space space."$space" left \
        --set space."$space" "${space_config[@]}" \
        --subscribe space."$space" mouse.clicked mouse.entered mouse.exited
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
    icon.padding_left="$PADDINGS_XLARGE"
    icon.padding_right="$PADDINGS_XLARGE"
    padding_left="$PADDINGS_NONE"
    padding_right="$PADDINGS_NONE"
    label.drawing=off
    associated_display=active
    click_script='yabai -m space --create && sketchybar --trigger space_change'
    background.drawing=off
    script="$HOME/.config/sketchybar/items/spaces.sh"
  )

  sketchybar --query add_space >/dev/null 2>&1 && sketchybar --remove add_space
  sketchybar --add item add_space left \
    --set add_space "${add_space_button[@]}" \
    --subscribe add_space mouse.clicked mouse.entered mouse.exited
}

# --- Spaces Bracket Management ----------------------------------------------
create_spaces_bracket() {
  local current_spaces="$1"
  
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
  BRACKET_ITEMS=$(echo "$current_spaces" | /usr/bin/sed 's/^/space./' | tr '\n' ' ')
  sketchybar --add bracket spaces $BRACKET_ITEMS add_space \
    --set spaces "${spaces_bracket[@]}"
}

# --- Mouse Event Handler ----------------------------------------------------
handle_mouse_events() {
  case "$SENDER" in
    "mouse.entered"|"mouse.exited"|"mouse.clicked")
      # Check if this is the add_space button
      if [[ "$NAME" == "add_space" ]]; then
        handle_special_hover_effects "$NAME" "$SENDER" "add_space"
      else
        handle_mouse_event "$NAME" "$SENDER"
        
        # Handle space clicks
        if [[ "$SENDER" == "mouse.clicked" && "$NAME" =~ ^space\. ]]; then
          space_id="${NAME#space.}"
          yabai -m space --focus "$space_id" 2>/dev/null || true
        fi
      fi
      ;;
    "space_change"|"windows_on_spaces")
      update_space_icons
      ;;
    *)
      # Initial creation or forced update
      CURRENT_SPACES=$(create_spaces)
      create_add_space_button
      create_spaces_bracket "$CURRENT_SPACES"
      
      # Position items
      LEFTMOST_SPACE=$(echo "$CURRENT_SPACES" | head -n1)
      RIGHTMOST_SPACE=$(echo "$CURRENT_SPACES" | tail -n1)

      positioning_args=()
      if [ -n "$LEFTMOST_SPACE" ]; then
        positioning_args+=(--move add_space after space."$RIGHTMOST_SPACE")
      fi

      if [ ${#positioning_args[@]} -gt 0 ]; then
        sketchybar "${positioning_args[@]}" 2>/dev/null || true
      fi

      # Initial icon update
      update_space_icons
      ;;
  esac
}

# --- Main Entry Point -------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ -n "${SENDER:-}" ]]; then
  handle_mouse_events
fi
