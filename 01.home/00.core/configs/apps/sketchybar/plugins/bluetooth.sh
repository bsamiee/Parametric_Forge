#!/bin/bash
# Title         : bluetooth.sh
# Author        : Parametric Forge
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/bluetooth.sh
# ----------------------------------------------------------------------------
# Bluetooth control + popup device list using blueutil and system tools
# Follows the volume/battery plugin pattern: NAME/SENDER switch + helpers
# shellcheck disable=SC1091
# shellcheck disable=SC2153  # NAME is provided by SketchyBar

set -euo pipefail

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Paths / State ----------------------------------------------------------
DEV_MAP_FILE="/tmp/sketchybar_bt_devices_map"     # slot|address|name
NEAR_MAP_FILE="/tmp/sketchybar_bt_nearby_map"     # slot|address|name
BATTERY_CACHE_FILE="/tmp/sketchybar_bt_battery_cache"
BATTERY_CACHE_TTL=30

# --- Utils ------------------------------------------------------------------
set_item() { local item="$1"; shift; sketchybar --set "$item" "$@" 2>/dev/null || true; }

hover_on()  { set_item "$1" background.drawing=on  background.color="$FAINT_GREY"; }
hover_off() { set_item "$1" background.drawing=off background.color="$TRANSPARENT"; }

have_blueutil() { command -v blueutil >/dev/null 2>&1; }

# Simple animation helper for temporary spinner/pulse effects
animate_item() {
  # usage: animate_item <item> <curve> <duration> key=val ...
  local item="$1" curve="$2" dur="$3"; shift 3
  sketchybar --animate "$curve" "$dur" --set "$item" "$@" >/dev/null 2>&1 || true
}

# --- blueutil wrappers ------------------------------------------------------
bt_power_get() { blueutil --power 2>/dev/null || echo 0; }
bt_power_set() { blueutil --power "$1" >/dev/null 2>&1 || true; }
bt_power_toggle() {
  local p
  p=$(bt_power_get)
  if [[ "$p" = 1 ]]; then
    bt_power_set 0
  else
    bt_power_set 1
  fi
}

# Discoverable: per docs, --discoverable (no arg) prints 1/0; keep legacy as fallback
bt_disc_get() {
  blueutil --discoverable 2>/dev/null || blueutil --is-discoverable 2>/dev/null || blueutil -d 2>/dev/null || echo 0
}
bt_disc_toggle() {
  local d; d=$(bt_disc_get)
  if [[ "$d" = 1 ]]; then blueutil --discoverable 0 >/dev/null 2>&1 || true
  else blueutil --discoverable 1 >/dev/null 2>&1 || true
  fi
}

bt_connected_count() {
  # Prefer JSON to avoid brittle parsing
  local j cnt
  j=$(blueutil --connected --format json 2>/dev/null || true)
  if [[ -n "$j" ]] && echo "$j" | grep -q '^\['; then
    cnt=$(echo "$j" | jq 'length' 2>/dev/null || echo 0)
    echo "${cnt:-0}"
  else
    blueutil --connected 2>/dev/null | grep -c '[:\-]\|[A-Fa-f0-9]\{12\}' || echo 0
  fi
}

# Paired devices: produce lines "address|name|connected"
bt_paired_list() {
  # Prefer JSON output; fallback to system_profiler JSON; then text
  local j
  j=$(blueutil --paired --format json 2>/dev/null || true)
  if [[ -n "$j" ]] && echo "$j" | grep -q '^\['; then
    echo "$j" | jq -r '.[] | select(.address!=null) | "\(.address)|\(.name // "Unknown")|\(if (.connected // false) then 1 else 0 end)"'
    return 0
  fi
  j=$(BLUEUTIL_USE_SYSTEM_PROFILER=1 blueutil --paired --format json 2>/dev/null || true)
  if [[ -n "$j" ]] && echo "$j" | grep -q '^\['; then
    echo "$j" | jq -r '.[] | select(.address!=null) | "\(.address)|\(.name // "Unknown")|\(if (.connected // false) then 1 else 0 end)"'
    return 0
  fi
  # Text fallback
  local out line id name connected
  out=$(blueutil --paired 2>/dev/null || true)
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if echo "$line" | grep -Eq '([A-Fa-f0-9]{2}[:-]){5}[A-Fa-f0-9]{2}'; then
      id=$(echo "$line" | grep -Eo '([A-Fa-f0-9]{2}[:-]){5}[A-Fa-f0-9]{2}' | head -n1)
      name=$(echo "$line" | sed -E 's/.*name: *'"'"'?([^'"'"']*)'"'"'?.*/\1/i; t; s/.* - //')
      connected=$(blueutil --is-connected "$id" 2>/dev/null || echo 0)
      echo "$id|${name:-$id}|$connected"
    fi
  done <<< "$out"
}

# --- Type + battery heuristics ---------------------------------------------
dev_icon_for_name() {
  case "$1" in
    *Magic*Mouse*|*MX*|*Mouse*) echo "$BLUETOOTH_MOUSE";;
    *Magic*Keyboard*|*Keychron*|*Keyboard*) echo "$BLUETOOTH_KEYBOARD";;
    *AirPods*|*Beats*|*Headphone*|*Earbud*|*EarPods*) echo "$BLUETOOTH_HEADPHONES";;
    *) echo "$BLUETOOTH_ON";;
  esac
}

# Battery snapshots (best-effort for Apple devices)
bat_mouse()    { ioreg -c AppleBluetoothHIDMouse    | awk '/BatteryPercent/ {gsub(/[^0-9]/,"",$NF); print $NF; exit}'; }
bat_keyboard() { ioreg -c AppleBluetoothHIDKeyboard | awk '/BatteryPercent/ {gsub(/[^0-9]/,"",$NF); print $NF; exit}'; }
bat_headphone(){
  # Try system_profiler first
  local v
  v=$(system_profiler SPBluetoothDataType 2>/dev/null | awk '/Battery Level:/ {gsub(/%/,"",$3); if($3~/^[0-9]+$/){print $3; exit}}')
  [[ -n "$v" ]] && { echo "$v"; return; }
  # Fallback to ioreg
  ioreg -c IOBluetoothDevice | awk '/BatteryPercent/ {gsub(/[^0-9]/,"",$NF); if($NF~/^[0-9]+$/){print $NF; exit}}'
}

bat_icon_for() {
  local p="$1"
  [[ -z "$p" ]] && { echo "$BATTERY_0"; return; }
  (( p >= 75 )) && { echo "$BATTERY_100"; return; }
  (( p >= 50 )) && { echo "$BATTERY_75"; return; }
  (( p >= 25 )) && { echo "$BATTERY_50"; return; }
  (( p >= 10 )) && { echo "$BATTERY_25"; return; }
  echo "$BATTERY_0"
}

bat_primary_snapshot() {
  # Cache a single representative battery reading to color the main icon
  local now ts val out
  now=$(date +%s)
  if [[ -f "$BATTERY_CACHE_FILE" ]]; then
    ts=$(stat -f %m "$BATTERY_CACHE_FILE" 2>/dev/null || echo 0)
    if (( now - ts < BATTERY_CACHE_TTL )); then
      cat "$BATTERY_CACHE_FILE"; return
    fi
  fi
  for fn in bat_mouse bat_keyboard bat_headphone; do
    val=$($fn 2>/dev/null || true)
    if [[ -n "$val" && "$val" =~ ^[0-9]+$ ]]; then
      out="$val"; break
    fi
  done
  echo "${out:-}" > "$BATTERY_CACHE_FILE" 2>/dev/null || true
  echo "${out:-}"
}

# --- UI refresh -------------------------------------------------------------
refresh_main() {
  local p disc cnt icon icolor
  if ! have_blueutil; then
    set_item bluetooth icon="$BLUETOOTH_OFF" icon.color="$DARK_GREY"
    return
  fi
  p=$(bt_power_get); disc=$(bt_disc_get); cnt=$(bt_connected_count)
  if [[ "$p" != 1 ]]; then
    icon="$BLUETOOTH_OFF"; icolor="$RED"
  else
    # Keep icon glyph reflective of state; bar icon color white when on
    if (( cnt > 0 )); then
      icon="$BLUETOOTH_ON"
    elif [[ "$disc" = 1 ]]; then
      icon="$BLUETOOTH_SEARCHING"
    else
      icon="$BLUETOOTH_ON"
    fi
    icolor="$WHITE"
  fi
  set_item bluetooth icon="$icon" icon.color="$icolor"
}

set_status_line() {
  local p cnt
  if ! have_blueutil; then
    set_item bluetooth.status label="Bluetooth: Unavailable" label.color="$PINK"
    return
  fi
  p=$(bt_power_get); cnt=$(bt_connected_count)
  if [[ "$p" != 1 ]]; then
    set_item bluetooth.status label="Bluetooth: Off" label.color="$PINK"
  else
    if (( cnt > 0 )); then
      set_item bluetooth.status label="On • ${cnt} connected" label.color="$PINK"
    else
      set_item bluetooth.status label="On • No devices connected" label.color="$PINK"
    fi
  fi
}

set_power_row() { :; }

set_discoverable_row() {
  local d
  if ! have_blueutil; then
    set_item bluetooth.discoverable icon="$BLUETOOTH_SEARCHING" label="Discoverable: Off" icon.color="$GREY"
    return
  fi
  d=$(bt_disc_get)
  if [[ "$d" = 1 ]]; then
    set_item bluetooth.discoverable icon="$BLUETOOTH_SEARCHING" label="Discoverable: On" icon.color="$CYAN"
  else
    set_item bluetooth.discoverable icon="$BLUETOOTH_SEARCHING" label="Discoverable: Off" icon.color="$GREY"
  fi
}

fill_device_slots() {
  if ! have_blueutil; then
    # Hide all device rows when blueutil is missing
    local i
    for i in $(seq 1 8); do
      set_item bluetooth.dev."$i" drawing=off
    done
    : > "$DEV_MAP_FILE" || true
    return
  fi
  : > "$DEV_MAP_FILE" || true
  local sorted i=1 id name conn icon state battery_str color
  # Prefer connected first, then alphabetical
  sorted=$(bt_paired_list | awk -F'|' '{print $0}' | sort -t'|' -k3,3r -k2,2)
  while IFS='|' read -r id name conn; do
    [[ -z "$id" ]] && continue
    icon=$(dev_icon_for_name "$name")
    # Choose font based on icon set (SF for device-specific, NF for generic BT)
    if [[ "$icon" == "$BLUETOOTH_ON" ]]; then
      icon_font="$TEXT_FONT:$BOLD_WEIGHT:$SIZE_MEDIUM"   # Nerd Font for generic BT glyph
    else
      icon_font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" # SF Symbols for device icons
    fi
    if [[ "$conn" = 1 ]]; then
      state="Connected"
      color="$WHITE"
    else
      state="Disconnected"
      color="$PRIMARY_GREY"
    fi
    battery_str=""
    # Best-effort battery hints by type
    case "$icon" in
      "$BLUETOOTH_MOUSE")    battery_str=$(bat_mouse) ;;
      "$BLUETOOTH_KEYBOARD") battery_str=$(bat_keyboard) ;;
      "$BLUETOOTH_HEADPHONES") battery_str=$(bat_headphone) ;;
    esac
    # unified icon that changes state via highlight rather than swapping glyphs
    set_item bluetooth.dev.$i \
      drawing=on \
      icon="$icon" \
      icon.color="$color" \
      icon.font="$icon_font" \
      icon.highlight="$([ "$conn" = 1 ] && echo on || echo off)" \
      icon.highlight_color="$GREEN" \
      label="${name} (${state})${battery_str:+  ${battery_str}%}" \
      label.color="$color"
    echo "$i|$id|$name" >> "$DEV_MAP_FILE"
    i=$((i+1)); [[ $i -gt 8 ]] && break
  done <<< "$sorted"
  # Hide remaining slots
  while (( i <= 8 )); do
    set_item bluetooth.dev.$i drawing=off
    i=$((i+1))
  done
}

refresh_all() {
  refresh_main
  set_status_line
  set_power_row
  set_discoverable_row
  fill_device_slots
  fill_battery_section
}

# --- Click handlers ---------------------------------------------------------
on_click_power()      { bt_power_toggle; sleep 0.5; refresh_all; }
on_click_discover()   { bt_disc_toggle;  sleep 0.2; refresh_all; }
on_click_device() {
  local slot addr

  slot=$(echo "$NAME" | awk -F'.' '{print $3}')
  addr=$(awk -F'|' -v s="$slot" '$1==s{print $2}' "$DEV_MAP_FILE" 2>/dev/null || true)
  [[ -z "$addr" ]] && return 0
  if [[ $(blueutil --is-connected "$addr" 2>/dev/null || echo 0) = 1 ]]; then
    blueutil --disconnect "$addr" >/dev/null 2>&1 || true
  else
    blueutil --connect "$addr"    >/dev/null 2>&1 || true
  fi
  sleep 1
  # Clear cached primary battery to reflect new device
  rm -f "$BATTERY_CACHE_FILE" 2>/dev/null || true
  refresh_all
}

# Nearby scan (best-effort). Uses blueutil --inquiry <seconds> if available.
bt_inquiry() {
  # Prefer JSON output to avoid brittle parsing
  local out
  out=$(blueutil --inquiry 5 --format json 2>/dev/null || true)
  if [[ -n "$out" ]] && echo "$out" | grep -q '^\['; then
    echo "$out" | jq -r '.[] | select(.address!=null) | "\(.address)|\(.name // "Unknown")"'
    return 0
  fi
  # Plain text fallback
  blueutil --inquiry 5 2>/dev/null || true
}

fill_nearby_slots() {
  : > "$NEAR_MAP_FILE" || true
  # Hide by default
  local i=1; while (( i <= 8 )); do set_item bluetooth.near.$i drawing=off; i=$((i+1)); done
  # Only when BT is on
  if [[ $(bt_power_get) != 1 ]]; then return; fi
  local out line id name color icon icon_font SEEN_IDS=""
  # Indicate scanning state in UI (spinner pulse)
  set_item bluetooth.scan drawing=on icon="$LOADING" label="Scanning..." icon.color="$CYAN"
  animate_item bluetooth.scan sin 30 icon.y_offset=2 icon.y_offset=0
  out=$(bt_inquiry)
  i=1
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if echo "$line" | grep -Eq '^[A-Fa-f0-9:-]{17}\|'; then
      id="${line%%|*}"
      name="${line#*|}"
      case " $SEEN_IDS " in *" $id "*) continue;; *) SEEN_IDS+=" $id";; esac
      color="$WHITE"
      icon=$(dev_icon_for_name "$name")
      if [[ "$icon" == "$BLUETOOTH_ON" ]]; then
        icon_font="$TEXT_FONT:$BOLD_WEIGHT:$SIZE_MEDIUM"
      else
        icon_font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM"
      fi
      set_item bluetooth.near.$i drawing=on icon="$icon" icon.color="$color" icon.font="$icon_font" label="${name}" label.color="$color"
      echo "$i|$id|$name" >> "$NEAR_MAP_FILE"
      i=$((i+1)); [[ $i -gt 8 ]] && break
    elif echo "$line" | grep -Eq '^[A-Fa-f0-9:-]{17}'; then
      # Plain text fallback: first token is address, rest is name
      id=$(echo "$line" | awk '{print $1}')
      case " $SEEN_IDS " in *" $id "*) continue;; *) SEEN_IDS+=" $id";; esac
      name=${line#*[A-Fa-f0-9:-]* }
      name=${name#- }
      color="$WHITE"
      icon=$(dev_icon_for_name "$name")
      if [[ "$icon" == "$BLUETOOTH_ON" ]]; then
        icon_font="$TEXT_FONT:$BOLD_WEIGHT:$SIZE_MEDIUM"
      else
        icon_font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM"
      fi
      set_item bluetooth.near.$i drawing=on icon="$icon" icon.color="$color" icon.font="$icon_font" label="${name}" label.color="$color"
      echo "$i|$id|$name" >> "$NEAR_MAP_FILE"
      i=$((i+1)); [[ $i -gt 8 ]] && break
    fi
  done <<< "$out"
  # Restore scan row label
  set_item bluetooth.scan drawing=off icon="$BLUETOOTH_SEARCHING" label="" icon.color="$WHITE"
}

# Populate accessory battery section for currently connected devices
fill_battery_section() {
  local j idx=1 addr name conn icon level color row
  # Hide all
  for row in 1 2 3; do
    set_item bluetooth.bat.$row drawing=off
  done
  # Build from paired list (connected only)
  while IFS='|' read -r addr name conn; do
    [[ -z "$addr" || "$conn" != 1 ]] && continue
    # Heuristics per device type
    icon=$(dev_icon_for_name "$name")
    case "$icon" in
      "$BLUETOOTH_MOUSE")    level=$(bat_mouse) ;;
      "$BLUETOOTH_KEYBOARD") level=$(bat_keyboard) ;;
      "$BLUETOOTH_HEADPHONES") level=$(bat_headphone) ;;
      *) level="" ;;
    esac
    if [[ -n "$level" && "$level" =~ ^[0-9]+$ ]]; then
      if (( level <= 15 )); then color="$RED"; elif (( level <= 30 )); then color="$ORANGE"; else color="$GREEN"; fi
      set_item bluetooth.bat.$idx \
        drawing=on \
        icon="$icon" \
        icon.color="$color" \
        label="${name}: ${level}%" \
        label.color="$color"
      idx=$((idx+1)); [[ $idx -gt 3 ]] && break
    fi
  done <<< "$(bt_paired_list)"
  # Show header only if something is drawn
  if (( idx > 1 )); then
    set_item bluetooth.batteryhdr drawing=on
  else
    set_item bluetooth.batteryhdr drawing=off
  fi
}

# --- Entry ------------------------------------------------------------------
case "${1:-}" in
  power_toggle) on_click_power; exit 0;;
  scan) fill_nearby_slots; exit 0;;
esac

case "$NAME" in
  bluetooth)
    case "${SENDER:-}" in
      mouse.entered) hover_on "$NAME" ;;
      mouse.exited)  hover_off "$NAME" ;;
      *) refresh_all ;;
    esac
    ;;
  bluetooth.discoverable)
    case "${SENDER:-}" in
      mouse.clicked)
        if have_blueutil; then on_click_discover; fi ;;
      mouse.entered) hover_on "$NAME" ;;
      mouse.exited)  hover_off "$NAME" ;;
    esac
    ;;
  bluetooth.dev.*)
    case "${SENDER:-}" in
      mouse.clicked)
        if have_blueutil; then
          on_click_device
        fi
        ;;
      mouse.entered) hover_on "$NAME" ;;
      mouse.exited)  hover_off "$NAME" ;;
    esac
    ;;
  bluetooth.scan)
    if [[ "${SENDER:-}" == "mouse.clicked" ]]; then
      fill_nearby_slots
    fi
    ;;
  bluetooth.near.*)
    case "${SENDER:-}" in
      mouse.clicked)
        # For nearby (not paired), guide to Control Center for pairing
        menubar -s "Control Center,Bluetooth" 2>/dev/null || open "x-apple.systempreferences:com.apple.preferences.Bluetooth"
        ;;
      mouse.entered) hover_on "$NAME" ;;
      mouse.exited)  hover_off "$NAME" ;;
    esac
    ;;
  bluetooth.settings)
    case "${SENDER:-}" in
      mouse.entered) hover_on "$NAME" ;;
      mouse.exited)  hover_off "$NAME" ;;
    esac
    ;;
  bluetooth.header|bluetooth.status)
    # no-op; handled by click_script or parent refresh
    ;;
  *)
    # Fallback: update overall UI
    refresh_all
    ;;
esac
