#!/bin/bash
# Title         : yabai.sh
# Author        : Bardia Samiee (adapted from FelixKratz)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/yabai.sh
# ----------------------------------------------------------------------------
# Window state management and app icon display for SketchyBar
# shellcheck disable=SC1091

# --- Window State Management ------------------------------------------------
window_state() {
  source "$HOME/.config/sketchybar/colors.sh"
  source "$HOME/.config/sketchybar/icons.sh"

  WINDOW=$(yabai -m query --windows --window)
  CURRENT=$(echo "$WINDOW" | jq '.["stack-index"]')

  args=()
  if [[ $CURRENT -gt 0 ]]; then
    LAST=$(yabai -m query --windows --window stack.last | jq '.["stack-index"]')
    args+=(--set "$NAME" icon="$YABAI_STACK" icon.color="$RED" label.drawing=on label="$(printf "[%s/%s]" "$CURRENT" "$LAST")")
    yabai -m config active_window_border_color "$RED" >/dev/null 2>&1 &

  else
    args+=(--set "$NAME" label.drawing=off)
    case "$(echo "$WINDOW" | jq '.["is-floating"]')" in
    "false")
      if [ "$(echo "$WINDOW" | jq '.["has-fullscreen-zoom"]')" = "true" ]; then
        args+=(--set "$NAME" icon="$YABAI_FULLSCREEN_ZOOM" icon.color="$GREEN")
        yabai -m config active_window_border_color "$GREEN" >/dev/null 2>&1 &
      elif [ "$(echo "$WINDOW" | jq '.["has-parent-zoom"]')" = "true" ]; then
        args+=(--set "$NAME" icon="$YABAI_PARENT_ZOOM" icon.color="$CYAN")
        yabai -m config active_window_border_color "$CYAN" >/dev/null 2>&1 &
      else
        args+=(--set "$NAME" icon="$YABAI_GRID" icon.color="$ORANGE")
        yabai -m config active_window_border_color "$WHITE" >/dev/null 2>&1 &
      fi
      ;;
    "true")
      args+=(--set "$NAME" icon="$YABAI_FLOAT" icon.color="$PURPLE")
      yabai -m config active_window_border_color "$PURPLE" >/dev/null 2>&1 &
      ;;
    esac
  fi

  sketchybar -m "${args[@]}"
}

# --- App Icon Management ----------------------------------------------------
windows_on_spaces() {
  source "$HOME/.config/sketchybar/colors.sh"
  
  # Single consolidated query for all data
  SPACE_DATA=$(yabai -m query --spaces --display)
  ACTIVE_SPACE=$(echo "$SPACE_DATA" | jq -r '.[] | select(.["has-focus"] == true) | .index')
  CURRENT_SPACES=$(echo "$SPACE_DATA" | jq -r '.[].index')
  
  # Batch query all windows once
  ALL_WINDOWS=$(yabai -m query --windows)

  args=()
  for space in $CURRENT_SPACES; do
    icon_strip=" "
    
    # Filter windows for this space from batch query
    apps=$(echo "$ALL_WINDOWS" | jq -r --arg space "$space" '.[] | select(.space == ($space | tonumber) and .["has-ax-reference"] == true) | .app')
    
    if [ "$apps" != "" ]; then
      while IFS= read -r app; do
        icon_strip+=" $("$HOME"/.config/sketchybar/plugins/icon_map.sh "$app")"
      done <<<"$apps"
    fi
    
    # Apply color based on active state
    if [ "$space" = "$ACTIVE_SPACE" ]; then
      args+=(--set space."$space" label="$icon_strip" label.drawing=on label.color="$WHITE")
    else
      args+=(--set space."$space" label="$icon_strip" label.drawing=on label.color="$FAINT_GREY")
    fi
  done

  sketchybar -m "${args[@]}"
}

# --- Mouse Event Handlers ---------------------------------------------------
mouse_clicked() {
  yabai -m window --toggle float
  window_state
}

# --- Centralized Space State Management ------------------------------------
update_space_indicators() {
  source "$HOME/.config/sketchybar/colors.sh"
  
  # Reuse data from windows_on_spaces if available, otherwise query
  if [ -z "$SPACE_DATA" ]; then
    SPACE_DATA=$(yabai -m query --spaces --display)
  fi
  
  ACTIVE_SPACE=$(echo "$SPACE_DATA" | jq -r '.[] | select(.["has-focus"] == true) | .index')
  CURRENT_SPACES=$(echo "$SPACE_DATA" | jq -r '.[].index')
  
  args=()
  for space in $CURRENT_SPACES; do
    if [ "$space" = "$ACTIVE_SPACE" ]; then
      args+=(--set space."$space" icon.color="$WHITE" icon.background.color="$CYAN")
    else
      args+=(--set space."$space" icon.color="$FAINT_GREY" icon.background.color="$TRANSPARENT")
    fi
  done
  
  sketchybar -m "${args[@]}"
}

# --- Space Management -------------------------------------------------------
recreate_spaces() {
  source "$HOME/.config/sketchybar/items/spaces.sh"
  update_space_indicators
}

# --- Event Debouncing --------------------------------------------------------
DEBOUNCE_FILE="/tmp/sketchybar_yabai_debounce"
DEBOUNCE_DELAY=0.1

debounce() {
  local current_time=$(date +%s.%N)
  local last_time=$(cat "$DEBOUNCE_FILE" 2>/dev/null || echo "0")
  
  if (( $(echo "$current_time - $last_time > $DEBOUNCE_DELAY" | bc -l) )); then
    echo "$current_time" > "$DEBOUNCE_FILE"
    return 0
  else
    return 1
  fi
}

# --- Event Dispatcher -------------------------------------------------------
case "$SENDER" in
"mouse.clicked")
  mouse_clicked
  ;;
"mouse.entered"|"mouse.exited")
  # Handle tooltip events
  "$HOME/.config/sketchybar/plugins/tooltip.sh" 2>/dev/null || true
  ;;
"forced")
  exit 0
  ;;
"window_focus")
  if debounce; then
    window_state
    SPACE_DATA=$(yabai -m query --spaces --display)
    update_space_indicators
  fi
  ;;
"windows_on_spaces")
  if debounce; then
    windows_on_spaces
  fi
  ;;
"space_change")
  # Always allow space recreation (important structural changes)
  recreate_spaces
  ;;
*)
  # Debounced fallback
  if debounce; then
    update_space_indicators
  fi
  ;;
esac
