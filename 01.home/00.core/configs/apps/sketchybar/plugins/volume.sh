#!/bin/bash
# Title         : volume.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/volume.sh
# ----------------------------------------------------------------------------
# Volume control with slider interface and precise adjustment controls
# shellcheck disable=SC2154
# shellcheck disable=SC1091

set -euo pipefail

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- UI Hover Helpers -------------------------------------------------------
hover_on() {
  local item="$1"
  sketchybar --set "$item" \
    background.drawing=on \
    background.color="$FAINT_GREY" \
    background.corner_radius="$RADIUS_MEDIUM" 2>/dev/null || true
}

hover_off() {
  local item="$1"
  sketchybar --set "$item" background.drawing=off 2>/dev/null || true
}

# --- Volume Management Functions --------------------------------------------
vol_get() {
  # Echo: "<percent> <muted:true|false>"
  local v m
  v=$(osascript -e 'output volume of (get volume settings)' 2>/dev/null || echo 0)
  m=$(osascript -e 'output muted of (get volume settings)' 2>/dev/null || echo false)
  printf '%s %s\n' "$v" "$m"
}

vol_set() {
  local v="$1"
  (( v < 0 )) && v=0
  (( v > 100 )) && v=100
  osascript -e "set volume output volume $v" >/dev/null 2>&1 || true
}

vol_toggle_mute() {
  local _v m
  read -r _v m < <(vol_get)
  if [[ "$m" == "true" ]]; then
    osascript -e 'set volume output muted false' >/dev/null 2>&1 || true
  else
    osascript -e 'set volume output muted true' >/dev/null 2>&1 || true
  fi
}

adjust_by() {
  local delta="$1" v m new
  read -r v m < <(vol_get)
  new=$(( v + delta ))
  (( new < 0 )) && new=0
  (( new > 100 )) && new=100
  vol_set "$new"
}

# --- Display Functions ------------------------------------------------------
icon_for_volume() {
  local p="$1" m="$2"
  if [[ "$m" == "true" ]] || (( p == 0 )); then
    echo "$VOLUME_0"; return
  fi
  (( p >= 60 )) && { echo "$VOLUME_100"; return; }
  (( p >= 30 )) && { echo "$VOLUME_66"; return; }
  (( p >= 10 )) && { echo "$VOLUME_33"; return; }
  echo "$VOLUME_10"
}

color_for_volume() {
  local p="$1" m="$2"
  # Main item color scheme: white when active, red when muted/off
  if [[ "$m" == "true" ]] || (( p == 0 )); then
    echo "$RED"; return
  fi
  echo "$WHITE"
}

refresh_all() {
  local v m icon color details
  # If the event provided INFO (new volume), accept it; otherwise query
  if [[ -n "${INFO:-}" && "${INFO}" =~ ^[0-9]+$ ]]; then
    read -r _ m < <(vol_get)
    v="$INFO"
  else
    read -r v m < <(vol_get)
  fi
  icon=$(icon_for_volume "$v" "$m")
  # Main icon: white when active, red when muted/off
  main_color=$(color_for_volume "$v" "$m")
  # Header icon in popup: keep prior colored scheme (purple when active, red when muted)
  if [[ "$m" == "true" ]] || (( v == 0 )); then
    header_color="$RED"
  else
    header_color="$PURPLE"
  fi
  details="$v%"; [[ "$m" == "true" ]] && details+=" • Muted"
  # Batch updates to reduce redraws
  sketchybar \
    --set volume icon="$icon" icon.color="$main_color" \
    --set volume.header icon="$icon" icon.color="$header_color" \
    --set volume.details label="$details" label.color="$PINK" \
    --set volume.slider slider.percentage="$v"
}

# --- Command Handlers -------------------------------------------------------
case "${1:-}" in
  inc)
    # Increase by 2% (or 10% with shift)
    step=2
    case "${MODIFIER:-}" in *shift*) step=10;; esac
    adjust_by "$step"
    refresh_all
    exit 0
    ;;
  dec)
    # Decrease by 2% (or 10% with shift)
    step=2
    case "${MODIFIER:-}" in *shift*) step=10;; esac
    adjust_by "-$step"
    refresh_all
    exit 0
    ;;
  mute)
    vol_toggle_mute
    refresh_all
    exit 0
    ;;
esac

# --- Event Handling ---------------------------------------------------------
case "$NAME" in
  volume)
    case "${SENDER:-}" in
      mouse.entered)
        hover_on "$NAME"
        ;;
      mouse.exited)
        hover_off "$NAME"
        ;;
      volume_change|system_woke)
        refresh_all
        ;;
      mouse.scrolled)
        # Adjust by 5% per scroll direction
        if [[ "${SCROLL_DELTA:-0}" -gt 0 ]]; then
          adjust_by 5
        else
          adjust_by -5
        fi
        refresh_all
        ;;
      *)
        refresh_all
        ;;
    esac
    ;;
  volume.slider)
    if [[ "${SENDER:-}" == "mouse.clicked" ]]; then
      vol_set "${PERCENTAGE:-0}"
    elif [[ "${SENDER:-}" == "mouse.scrolled" ]]; then
      if [[ "${SCROLL_DELTA:-0}" -gt 0 ]]; then
        adjust_by 5
      else
        adjust_by -5
      fi
    fi
    refresh_all
    ;;
  volume.inc|volume.dec|volume.settings)
    case "${SENDER:-}" in
      mouse.entered) hover_on "$NAME" ;;
      mouse.exited)  hover_off "$NAME" ;;
    esac
    # No full refresh on hover-only events for snappy UI
    ;;
  *)
    refresh_all
    ;;
esac
