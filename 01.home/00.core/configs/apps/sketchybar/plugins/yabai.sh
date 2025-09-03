#!/bin/bash
# Title         : yabai.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/yabai.sh
# ----------------------------------------------------------------------------
# Window state visualization and dynamic space app icon management for yabai integration
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/plugins/icon_map.sh"

# --- Window State Functions -----------------------------------------------
update_window_state() {
  local window_info current_stack
  window_info=$(yabai -m query --windows --window 2>/dev/null || echo '{}')
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

# --- Space Icon Management -----------------------------------------------
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

# --- Space Recreation -----------------------------------------------------
recreate_spaces() {
  source "$HOME/.config/sketchybar/items/spaces.sh" 2>/dev/null || true
}

# --- Mouse Handlers -------------------------------------------------------
handle_click() {
  yabai -m window --toggle float 2>/dev/null || true
  update_window_state
}


# --- Event Handler --------------------------------------------------------
case "$SENDER" in
  "mouse.clicked")
    handle_click
    ;;
  "mouse.entered")
    # Mouse entered - no tooltip
    ;;
  "mouse.exited")
    # Mouse exited - no tooltip
    ;;
  "window_focus")
    update_window_state
    ;;
  "windows_on_spaces")
    update_space_icons
    ;;
  "space_change")
    recreate_spaces
    ;;
  "forced")
    exit 0
    ;;
  *)
    # Default: update both window state and space icons
    update_window_state
    update_space_icons
    ;;
esac
