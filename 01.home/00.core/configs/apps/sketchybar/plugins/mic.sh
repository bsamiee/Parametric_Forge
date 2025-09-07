#!/bin/bash
# Title         : mic.sh
# Author        : Parametric Forge
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/mic.sh
# ----------------------------------------------------------------------------
# Microphone control with popup slider, mute toggle, scroll adjust, and OFF state
# Mirrors the structure and code quality of volume.sh
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

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/sketchybar"
mkdir -p "$STATE_DIR"
MIC_PREV_STATE="$STATE_DIR/mic_prev.state"

# --- Mic Management ---------------------------------------------------------
mic_get() {
  local v
  v=$(osascript -e 'input volume of (get volume settings)' 2>/dev/null || echo 0)
  # ensure integer
  printf '%d\n' "${v:-0}" 2>/dev/null || echo 0
}

mic_set() {
  local v="${1:-0}"
  (( v < 0 )) && v=0
  (( v > 100 )) && v=100
  osascript -e "set volume input volume $v" >/dev/null 2>&1 || true
}

mic_toggle_mute() {
    local v prev
  v=$(mic_get)
  if (( v == 0 )); then
    # Unmute: restore previous volume or default 50
    if [[ -r "$MIC_PREV_STATE" ]]; then
      read -r prev < "$MIC_PREV_STATE" || prev=50
    else
      prev=50
    fi
    (( prev <= 0 )) && prev=50
    mic_set "$prev"
  else
    # Mute: store volume and set to 0
    printf '%d\n' "$v" > "$MIC_PREV_STATE" 2>/dev/null || true
    mic_set 0
  fi
}

adjust_by() {
  local delta="${1:-0}" v new
  v=$(mic_get)
  new=$(( v + delta ))
  (( new < 0 )) && new=0
  (( new > 100 )) && new=100
  mic_set "$new"
}

# --- Input device helpers ---------------------------------------------------
current_input_device() {
  if command -v SwitchAudioSource >/dev/null 2>&1; then
    SwitchAudioSource -t input -c 2>/dev/null || true
  fi
}

list_input_devices() {
  if command -v SwitchAudioSource >/dev/null 2>&1; then
    SwitchAudioSource -t input -a 2>/dev/null || true
  fi
}

mic_is_off() {
  # "Off" is distinct from mute: means no input device available/selected
  if ! command -v SwitchAudioSource >/dev/null 2>&1; then
    return 1
  fi
  local cur devices
  cur=$(SwitchAudioSource -t input -c 2>/dev/null || echo "")
  devices=$(SwitchAudioSource -t input -a 2>/dev/null || echo "")
  [[ -z "$devices" ]] && return 0
  [[ -z "$cur" ]] && return 0
  return 1
}


cycle_input_device() {
  command -v SwitchAudioSource >/dev/null 2>&1 || return 0
  local cur devices next found=0 first=""
  cur=$(SwitchAudioSource -t input -c 2>/dev/null || echo "")
  devices=$(SwitchAudioSource -t input -a 2>/dev/null || echo "")
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    [[ -z "$first" ]] && first="$d"
    if [[ "$found" -eq 1 ]]; then
      next="$d"; break
    fi
    if [[ "$d" == "$cur" ]]; then
      found=1
    fi
  done <<< "$devices"
  [[ -z "$next" ]] && next="$first"
  if [[ -n "$next" ]]; then SwitchAudioSource -t input -s "$next" >/dev/null 2>&1 || true; fi
}

# --- Display helpers --------------------------------------------------------
icon_for_mic() {
  local p="${1:-0}" off="${2:-0}"
  if [[ "$off" == "1" ]]; then
    echo "$MIC_OFF"; return
  fi
  if (( p == 0 )); then
    echo "$MIC_MUTED"; return
  fi
  echo "$MIC_ON"
}

color_for_mic() {
  local p="${1:-0}" off="${2:-0}"
  # Main item scheme: white when active, red when muted or off
  if [[ "$off" == "1" ]] || (( p == 0 )); then
    echo "$RED"; return
  fi
  echo "$WHITE"
}

refresh_all() {
  local v icon color details dev off=0
  v=$(mic_get)
  if mic_is_off; then off=1; fi
  icon=$(icon_for_mic "$v" "$off")
  # Main icon: white active, red muted/off
  main_color=$(color_for_mic "$v" "$off")
  # Header icon color (popup): keep pink when active, red when muted/off
  if [[ "$off" == "1" ]] || (( v == 0 )); then
    header_color="$RED"
  else
    header_color="$PINK"
  fi

  # Optional device name if available
  dev=$(current_input_device || true)
  if [[ "$off" == "1" ]]; then
    details="Off"
  else
    details="$v%"
    (( v == 0 )) && details+=" • Muted"
    [[ -n "$dev" ]] && details+=" • $dev"
  fi

  # Batch updates
  sketchybar \
    --set mic icon="$icon" icon.color="$main_color" \
    --set mic.header icon="$icon" icon.color="$header_color" \
    --set mic.details label="$details" label.color="$PINK" \
    --set mic.slider slider.percentage="$v" \
    --set mic.slider drawing="$([[ "$off" == "1" ]] && echo off || echo on)"

  # Toggle cycle row visibility based on SwitchAudioSource
  if command -v SwitchAudioSource >/dev/null 2>&1; then
    sketchybar --set mic.cycle drawing=on
  else
    sketchybar --set mic.cycle drawing=off
  fi
}

# --- Command entrypoints (for click_script) ---------------------------------
case "${1:-}" in
  inc)
    step=2
    case "${MODIFIER:-}" in *shift*) step=10;; esac
    adjust_by "$step"
    refresh_all
    exit 0
    ;;
  dec)
    step=2
    case "${MODIFIER:-}" in *shift*) step=10;; esac
    adjust_by "-$step"
    refresh_all
    exit 0
    ;;
  mute)
    mic_toggle_mute
    refresh_all
    exit 0
    ;;
  cycle)
    cycle_input_device
    refresh_all
    exit 0
    ;;
esac

# --- Event Handling ---------------------------------------------------------
case "$NAME" in
  mic)
    case "${SENDER:-}" in
      mouse.entered)
        hover_on "$NAME"
        ;;
      mouse.exited)
        hover_off "$NAME"
        ;;
      system_woke)
        refresh_all
        ;;
      mouse.scrolled)
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
  mic.slider)
    if [[ "${SENDER:-}" == "mouse.clicked" ]]; then
      mic_set "${PERCENTAGE:-0}"
    elif [[ "${SENDER:-}" == "mouse.scrolled" ]]; then
      if [[ "${SCROLL_DELTA:-0}" -gt 0 ]]; then
        adjust_by 5
      else
        adjust_by -5
      fi
    fi
    refresh_all
    ;;
  mic.inc|mic.dec|mic.settings)
    case "${SENDER:-}" in
      mouse.entered) hover_on "$NAME" ;;
      mouse.exited)  hover_off "$NAME" ;;
    esac
    # No full refresh on hover-only events for snappy UI
    ;;
  mic.cycle)
    if [[ "${SENDER:-}" == "mouse.clicked" ]]; then
      cycle_input_device
    fi
    refresh_all
    ;;
  *)
    refresh_all
    ;;
esac
