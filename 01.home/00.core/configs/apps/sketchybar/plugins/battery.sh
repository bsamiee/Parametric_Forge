#!/bin/bash
# Title         : battery.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/battery.sh
# ----------------------------------------------------------------------------
# Advanced battery management with charging limits, Top Up mode, and adapter control
# shellcheck disable=SC2154
# shellcheck disable=SC1091

set -euo pipefail

# --- UI Helpers -------------------------------------------------------------
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

flash_item() {
  local item="$1" color="${2:-$FAINT_GREY}" dur="${3:-0.12}"
  sketchybar --set "$item" background.drawing=on background.color="$color" 2>/dev/null || true
  sleep "$dur"
  sketchybar --set "$item" background.drawing=off 2>/dev/null || true
}

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# Assume the battery CLI is installed and in PATH
BATTERY_BIN="${BATTERY_BIN:-battery}"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/sketchybar"
mkdir -p "$STATE_DIR"
TOPUP_STATE="$STATE_DIR/battery_topup.state"
DISCHARGE_STATE="$STATE_DIR/battery_discharge.state"
LIMIT_STATE="$STATE_DIR/battery_limit.state"
TOPUP_PREV_LIMIT="$STATE_DIR/battery_topup_prev_limit.state"
TEMP_GUARD_STATE="$STATE_DIR/battery_temp_guard.state"

# --- Utility Functions ------------------------------------------------------
use_battery() { return 0; }
have() { command -v "$1" >/dev/null 2>&1; }

read_temp_c() {
  # Try ioreg AppleSmartBattery Temperature (in 0.1°C)
  local raw
  raw=$(ioreg -r -n AppleSmartBattery 2>/dev/null | awk '/"Temperature"/ {print $3; exit}')
  if [[ -n "$raw" ]]; then
    # raw appears to be in 0.1°C units for many models
    awk -v v="$raw" 'BEGIN { printf("%.1f\n", v/100.0) }'
    return
  fi
  # Fallback: try powermetrics (may require privileges) — return empty on failure
  echo ""
}

read_health() {
  # Returns: "<cycles> <health_pct>"
  local cc mc dc
  eval "$(ioreg -r -n AppleSmartBattery 2>/dev/null | awk '
    /"CycleCount"/ { printf("cc=%s;", $3) }
    /"MaxCapacity"/ { printf("mc=%s;", $3) }
    /"DesignCapacity"/ { printf("dc=%s;", $3) }
  ')"
  if [[ -n "$dc" && "$dc" -gt 0 && -n "$mc" ]]; then
    awk -v cc="$cc" -v mc="$mc" -v dc="$dc" 'BEGIN { printf("%d %.0f\n", cc, (mc/dc)*100.0) }'
    return
  fi
  echo " "
}

apply_limit() {
  local target="${1:-}"
  [[ -z "$target" ]] && return 0
  if use_battery; then
    "$BATTERY_BIN" maintain "$target" >/dev/null 2>&1 || true
  fi
}

temp_guard_should_engage() {
  [[ "${TEMP_GUARD_ENABLED:-1}" = "1" ]] || return 1
  local t p
  t=$(read_temp_c)
  [[ -z "$t" ]] && return 1
  # Engage when at/above max threshold
  awk -v temp="$t" -v maxc="${TEMP_GUARD_MAX_C:-40}" 'BEGIN { exit !(temp >= maxc) }'
}

temp_guard_should_release() {
  [[ "${TEMP_GUARD_ENABLED:-1}" = "1" ]] || return 1
  local t
  t=$(read_temp_c)
  [[ -z "$t" ]] && return 1
  # Release when at/below resume threshold
  awk -v temp="$t" -v res="${TEMP_GUARD_RESUME_C:-38}" 'BEGIN { exit !(temp <= res) }'
}

# --- Battery State Management -----------------------------------------------
read_batt() {
  local raw header body percent status time power
  raw=$(pmset -g batt 2>/dev/null || true)
  if grep -qi "no.*batter" <<< "$raw"; then
    printf '%s %s %s\n' "-1" "none" "N/A"
    return
  fi
  header=$(sed -n '1p' <<< "$raw")
  body=$(sed -n '2p' <<< "$raw")

  power=$(awk -F"'" '/Now drawing from/{print $2}' <<< "$header" 2>/dev/null)
  percent=$(grep -Eo '[0-9]+%' <<< "$body" | head -1 | tr -d '%' )
  [[ -z "$percent" ]] && percent=0

  if [[ "$power" == "AC Power" ]]; then
    if grep -qi 'not[[:space:]]\?charging' <<< "$body"; then
      status=plugged_not_charging
    elif grep -qi 'charged' <<< "$body"; then
      status=plugged_not_charging
    elif grep -qi 'finishing[[:space:]]\?charge' <<< "$body"; then
      status=charging
    elif grep -qi 'charging' <<< "$body"; then
      status=charging
    else
      status=plugged_not_charging
    fi
  else
    if grep -qi 'discharging' <<< "$body"; then
      status=discharging
    else
      status=discharging
    fi
  fi

  time=$(grep -Eo '[0-9]+:[0-9]+' <<< "$body" | head -1 || true)
  printf '%s %s %s\n' "$percent" "$status" "${time:-N/A}"
}

current_limit() {
  local lim
  if use_battery; then
    lim=$("$BATTERY_BIN" status 2>/dev/null | awk '/maintain/ {for(i=1;i<=NF;i++) if($i=="maintain"){print $(i+1); exit}}')
    if [[ -n "$lim" ]]; then
      echo "$lim"
      return
    fi
  fi
  if [[ -r "$LIMIT_STATE" ]]; then
    read -r lim < "$LIMIT_STATE" || lim=100
    echo "${lim:-100}"
  else
    echo 100
  fi
}

set_limit() {
  local target="${1:-80}"
  printf '%s\n' "$target" > "$LIMIT_STATE" || true
  if use_battery; then
    if [[ "$target" == "100" ]]; then
      "$BATTERY_BIN" maintain stop >/dev/null 2>&1 || true
    else
      "$BATTERY_BIN" maintain "$target" >/dev/null 2>&1 || true
    fi
  fi
}

toggle_adapter() {
  if use_battery; then
    if "$BATTERY_BIN" status 2>/dev/null | grep -q 'adapter.*off'; then
      "$BATTERY_BIN" adapter on >/dev/null 2>&1 || true
    else
      "$BATTERY_BIN" adapter off >/dev/null 2>&1 || true
    fi
  fi
}

adapter_off() {
  if use_battery; then
    "$BATTERY_BIN" status 2>/dev/null | grep -q 'adapter.*off'
    return
  fi
  return 1
}

topup_toggle() {
  if [[ -f "$TOPUP_STATE" ]]; then
    rm -f "$TOPUP_STATE"
    local prev
    if [[ -r "$TOPUP_PREV_LIMIT" ]]; then
      read -r prev < "$TOPUP_PREV_LIMIT" || prev=100
    else
      prev=100
    fi
    rm -f "$TOPUP_PREV_LIMIT" || true
    set_limit "$prev"
  else
    touch "$TOPUP_STATE"
    current_limit >"$TOPUP_PREV_LIMIT" 2>/dev/null || true
    set_limit 100
  fi
}

# --- Display Functions ------------------------------------------------------
icon_for() {
  local p="$1" chg="$2"
  if [[ "$chg" == charging ]]; then echo "$BATTERY_CHARGING"; return; fi
  (( p <= 20 )) && { echo "$BATTERY_0"; return; }
  (( p <= 40 )) && { echo "$BATTERY_25"; return; }
  (( p <= 60 )) && { echo "$BATTERY_50"; return; }
  (( p <= 80 )) && { echo "$BATTERY_75"; return; }
  echo "$BATTERY_100"
}

color_for() {
  local p="$1" chg="$2"
  if [[ "$chg" == charging ]]; then echo "$GREEN"; return; fi
  if [[ "$chg" == plugged_not_charging ]]; then echo "$CYAN"; return; fi
  (( p <= 15 )) && { echo "$LIGHT_RED"; return; }
  (( p <= 30 )) && { echo "$LIGHT_ORANGE"; return; }
  (( p <= 50 )) && { echo "$LIGHT_YELLOW"; return; }
  echo "$WHITE"
}

refresh_all() {
  local p s t lim icon color details
  read -r p s t < <(read_batt)
  if [[ "$p" == "-1" ]]; then
    sketchybar --set battery drawing=off
    return
  else
    sketchybar --set battery drawing=on
  fi
  lim=$(current_limit)
  color=$(color_for "$p" "$s")

  # Discharge-to-limit automation: if active and above limit, keep adapter off until <= limit
  if [[ -f "$DISCHARGE_STATE" ]]; then
    if (( p <= lim )); then
      # Reached target -> stop discharging and restore adapter
      rm -f "$DISCHARGE_STATE" 2>/dev/null || true
      if use_battery; then "$BATTERY_BIN" adapter on >/dev/null 2>&1 || true; fi
    else
      if use_battery; then "$BATTERY_BIN" adapter off >/dev/null 2>&1 || true; fi
    fi
  fi

  # Temperature Guard: always-on, no UI, sane defaults
  # Do not interfere with manual Discharge mode; cancel Top Up on engage
  if use_battery; then
    if [[ ! -f "$DISCHARGE_STATE" ]]; then
      if temp_guard_should_engage; then
        # Only engage if above min percent guard
        if (( p >= ${TEMP_GUARD_MIN_PERCENT:-40} )); then
          # Cancel top-up if active
          if [[ -f "$TOPUP_STATE" ]]; then rm -f "$TOPUP_STATE" "$TOPUP_PREV_LIMIT" 2>/dev/null || true; fi
          touch "$TEMP_GUARD_STATE"
          "$BATTERY_BIN" adapter off >/dev/null 2>&1 || true
        fi
      elif [[ -f "$TEMP_GUARD_STATE" ]] && temp_guard_should_release; then
        rm -f "$TEMP_GUARD_STATE" 2>/dev/null || true
        # Restore adapter if not in discharge mode
        "$BATTERY_BIN" adapter on >/dev/null 2>&1 || true
      fi
    fi
  fi

  # Auto-sailing (skip during Top Up or Discharge)
  if [[ ! -f "$TOPUP_STATE" && ! -f "$DISCHARGE_STATE" ]]; then
    local range lower
    range=${SAILING_RANGE:-5}
    [[ -z "$range" ]] && range=5
    [[ "$range" =~ ^[0-9]+$ ]] || range=5
    lower=$(( lim - range ))
    (( lower < 0 )) && lower=0
    if (( p >= lim )); then
      apply_limit "$lower"
    elif (( p <= lower )); then
      apply_limit "$lim"
    else
      apply_limit "$lower"
    fi
  fi

  # Icon
  icon=$(icon_for "$p" "$s")

  # Bare icon on the bar; all info lives in the popup
  sketchybar --set battery icon="$icon" icon.color="$color"

  # Update popup header dynamically by state
  header_icon="$icon"
  case "$s" in
    charging)
      header_icon="$BATTERY_CHARGING"
      ;;
    plugged_not_charging)
      # Show current battery level icon for direct power instead of adapter icon
      header_icon="$icon"
      ;;
    *)
      # discharging or unknown uses computed icon
      ;;
  esac
  sketchybar --set battery.header icon="$header_icon" icon.color="$color"

  # Update popup bits
  display_status="$s"
  if [[ "$s" == "plugged_not_charging" ]]; then
    display_status="direct power"
  fi
  details="$p% • $display_status"
  [[ "$t" != "N/A" ]] && details+=" • $t"
  if adapter_off; then details+=" • Adapter OFF"; fi
  [[ -f "$TOPUP_STATE" ]] && details+=" • Top Up"
  [[ -f "$DISCHARGE_STATE" ]] && details+=" • Discharging to $lim%"
  [[ -f "$TEMP_GUARD_STATE" ]] && details+=" • Heat Guard"
  sketchybar --set battery.details label="$details" label.color="$PINK"

  # Power draw source line (below slider): show clean, professional summary
  # True split percentages are not exposed via pmset or the battery CLI; represent
  # as 100% Adapter or 100% Battery based on current source.
  local power_label
  if adapter_off; then
    power_label="Power • Battery 100%"
  else
    case "$s" in
      charging|plugged_not_charging)
        power_label="Power • Adapter 100%"
        ;;
      *)
        power_label="Power • Battery 100%"
        ;;
    esac
  fi
  sketchybar --set battery.power label="$power_label" label.color="$GREY"

  # Temperature on separate line
  temp_reading=$(read_temp_c)
  if [[ -n "$temp_reading" ]]; then
    sketchybar --set battery.temp drawing=on label="${temp_reading}°C • temperature" label.color="$PINK"
  else
    sketchybar --set battery.temp drawing=off
  fi

  # Always show advanced controls; assume 'battery' CLI is available
  sketchybar --set battery.slider drawing=on slider.percentage="$lim"
  sketchybar --set battery.inc drawing=on
  sketchybar --set battery.dec drawing=on
  sketchybar --set battery.topup drawing=on
  sketchybar --set battery.adapter drawing=on
  sketchybar --set battery.discharge drawing=on
  sketchybar --set battery.limit_label label="${lim}% • Charging Threshold" label.color="$PINK"

  # Reflect active states on popup buttons
  if [[ -f "$TOPUP_STATE" ]]; then
    sketchybar --set battery.topup icon.color="$LIGHT_GREEN"
  else
    sketchybar --set battery.topup icon.color="$WHITE"
  fi
  if adapter_off; then
    sketchybar --set battery.adapter icon.color="$LIGHT_ORANGE" label="Adapter (OFF)"
  else
    sketchybar --set battery.adapter icon.color="$WHITE" label="Adapter"
  fi
  if [[ -f "$DISCHARGE_STATE" ]]; then
    sketchybar --set battery.discharge icon.color="$LIGHT_ORANGE"
  else
    sketchybar --set battery.discharge icon.color="$WHITE"
  fi
}

# --- Command Handlers -------------------------------------------------------
case "${1:-}" in
  topup)
    [[ -n "${NAME:-}" ]] && flash_item "$NAME"
    topup_toggle
    refresh_all
    exit 0
    ;;
  adapter)
    [[ -n "${NAME:-}" ]] && flash_item "$NAME"
    toggle_adapter
    refresh_all
    exit 0
    ;;
  discharge)
    [[ -n "${NAME:-}" ]] && flash_item "$NAME"
    if [[ -f "$DISCHARGE_STATE" ]]; then
      rm -f "$DISCHARGE_STATE" 2>/dev/null || true
      if use_battery; then "$BATTERY_BIN" adapter on >/dev/null 2>&1 || true; fi
    else
      # Start discharging to the current limit (adapter off while above limit)
      touch "$DISCHARGE_STATE"
      if use_battery; then "$BATTERY_BIN" adapter off >/dev/null 2>&1 || true; fi
      # Cancel Top Up if any
      rm -f "$TOPUP_STATE" "$TOPUP_PREV_LIMIT" 2>/dev/null || true
    fi
    refresh_all
    exit 0
    ;;
  inc)
    [[ -n "${NAME:-}" ]] && flash_item "$NAME"
    # Increase limit by 1% (or 5% with shift)
    cur=$(current_limit)
    step=1
    case "${MODIFIER:-}" in *shift*) step=5;; esac
    new=$((cur + step))
    (( new > 100 )) && new=100
    rm -f "$TOPUP_STATE" "$TOPUP_PREV_LIMIT" 2>/dev/null || true
    set_limit "$new"
    refresh_all
    exit 0
    ;;
  dec)
    [[ -n "${NAME:-}" ]] && flash_item "$NAME"
    # Decrease limit by 1% (or 5% with shift)
    cur=$(current_limit)
    step=1
    case "${MODIFIER:-}" in *shift*) step=5;; esac
    new=$((cur - step))
    (( new < 0 )) && new=0
    rm -f "$TOPUP_STATE" "$TOPUP_PREV_LIMIT" 2>/dev/null || true
    set_limit "$new"
    refresh_all
    exit 0
    ;;
esac

# --- Event Handling ---------------------------------------------------------
case "$NAME" in
  battery)
    case "${SENDER:-}" in
      mouse.entered)
        hover_on "$NAME"
        ;;
      mouse.exited)
        hover_off "$NAME"
        ;;
      *)
        # Any other trigger on the main item -> refresh
        refresh_all
        ;;
    esac
    ;;
  battery.slider)
    # Slider click provides $PERCENTAGE
    if [[ "${SENDER:-}" == "mouse.clicked" ]]; then
      # Any manual change cancels Top Up
      rm -f "$TOPUP_STATE" "$TOPUP_PREV_LIMIT" 2>/dev/null || true
      set_limit "${PERCENTAGE:-100}"
      # Flash label for feedback
      sketchybar --set battery.limit_label label.color="$WHITE"
      sleep 0.12
      sketchybar --set battery.limit_label label.color="$PINK"
    elif [[ "${SENDER:-}" == "mouse.scrolled" ]]; then
      # Adjust by step per notch based on scroll direction
      cur=""
      new=""
      step=${LIMIT_STEP:-5}
      [[ -z "$step" ]] && step=5
      [[ "$step" =~ ^[0-9]+$ ]] || step=5
      cur=$(current_limit)
      if [[ "${SCROLL_DELTA:-0}" -gt 0 ]]; then
        new=$((cur + step))
      else
        new=$((cur - step))
      fi
      (( new < 0 )) && new=0
      (( new > 100 )) && new=100
      rm -f "$TOPUP_STATE" "$TOPUP_PREV_LIMIT" 2>/dev/null || true
      set_limit "$new"
      sketchybar --set battery.limit_label label.color="$WHITE"
      sleep 0.12
      sketchybar --set battery.limit_label label.color="$PINK"
    fi
    refresh_all
    ;;
  battery.topup|battery.adapter|battery.discharge|battery.inc|battery.dec)
    case "${SENDER:-}" in
      mouse.entered)
        hover_on "$NAME"
        ;;
      mouse.exited)
        hover_off "$NAME"
        ;;
    esac
    # Avoid full refresh on hover-only events for responsive UI
    ;;
  *)
    # Fallback (e.g. limit_label/details updates)
    refresh_all
    ;;
esac
