#!/bin/bash
# Title         : wifi.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/wifi.sh
# ----------------------------------------------------------------------------
# WiFi status monitor with signal strength detection and Control Center integration
# shellcheck disable=SC1091

# --- Configuration --------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Signal Strength Detection -------------------------------------------
get_signal_strength() {
  local wdutil_data rssi signal_percent signal_quality signal_color signal_icon

  # Get RSSI using modern wdutil command (passed as parameter for efficiency)
  wdutil_data="$1"
  rssi=$(echo "$wdutil_data" | awk '/RSSI/ {gsub(/dBm/, "", $2); print $2}')

  # Handle no RSSI data
  if [[ -z "$rssi" || "$rssi" == "0" ]]; then
    echo "0|$WIFI_SIGNAL_3|Unknown|$GREY"
    return
  fi

  # Convert RSSI to percentage (typical range: -100 to -30 dBm)
  # Formula: ((rssi + 100) / 70) * 100, clamped to 0-100
  signal_percent=$(awk "BEGIN {
    percent = (($rssi + 100) / 70) * 100;
    if (percent < 0) percent = 0;
    if (percent > 100) percent = 100;
    printf \"%.0f\", percent
  }")

  # Determine signal quality with proper SF Symbol icons
  if [[ $signal_percent -ge 70 ]]; then
    signal_quality="Excellent"
    signal_color="$GREEN"
    signal_icon="$WIFI_SIGNAL_3"
  elif [[ $signal_percent -ge 40 ]]; then
    signal_quality="Good" 
    signal_color="$YELLOW"
    signal_icon="$WIFI_SIGNAL_2"
  elif [[ $signal_percent -ge 10 ]]; then
    signal_quality="Fair"
    signal_color="$ORANGE"
    signal_icon="$WIFI_SIGNAL_1"
  else
    signal_quality="Weak"
    signal_color="$RED"
    signal_icon="$WIFI_SIGNAL_1"
  fi

  echo "$signal_percent|$signal_icon|$signal_quality|$signal_color"
}

# --- Enhanced Status Detection --------------------------------------------
get_wifi_status() {
  local wifi_port wifi_network hotspot ip_address public_ip
  local icon icon_color label signal_data signal_percent signal_icon signal_quality signal_color

  # Get WiFi hardware port
  wifi_port=$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2}')

  # Get current network info using modern wdutil command
  local wdutil_info
  wdutil_info=$(wdutil info 2>/dev/null)
  wifi_network=$(echo "$wdutil_info" | awk '/SSID/ {for(i=2;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":""); print ""}')
  
  # Fallback to system_profiler if wdutil fails
  if [[ -z "$wifi_network" ]]; then
    wifi_network=$(system_profiler SPAirPortDataType | awk '/Current Network/ {getline;$1=$1; gsub(":",""); print;exit}')
  fi

  # Get hotspot and IP info
  hotspot=$(ipconfig getsummary "$wifi_port" | grep sname | awk '{print $3}')
  ip_address=$(scutil --nwi | grep address | sed 's/.*://' | tr -d ' ' | head -1)

  # Check internet connectivity
  public_ip=1
  if curl -m 2 https://ipinfo.io >/dev/null 2>&1; then
    public_ip=0
  fi

  # Get signal strength data (reuse wdutil_info for efficiency)
  signal_data=$(get_signal_strength "$wdutil_info")
  IFS='|' read -r signal_percent signal_icon signal_quality signal_color <<< "$signal_data"

  # Set icon and color based on WiFi state
  if [[ -n "$hotspot" ]]; then
    # Personal Hotspot active
    icon="$WIFI_HOTSPOT"
    icon_color="$CYAN"
    label="$hotspot"
  elif [[ -n "$wifi_network" ]]; then
    # Connected to WiFi network with signal strength
    if [[ $signal_percent -gt 0 ]]; then
      icon="$signal_icon"
      icon_color="$signal_color"
      label="$wifi_network ${signal_percent}%"
    else
      icon="$WIFI_SIGNAL_3"
      icon_color="$GREEN"
      label="$wifi_network"
    fi
  elif [[ -n "$ip_address" ]]; then
    # Has IP but no network name
    icon="$WIFI_SIGNAL_3"
    icon_color="$PINK"
    label="Connected"
  else
    # No WiFi connection
    icon="$WIFI_OFF"
    icon_color="$RED"
    label="Offline"
  fi

  # Handle no internet access
  if [[ $public_ip != "0" && "$label" != "Offline" ]]; then
    icon="$WIFI_ERROR"
    icon_color="$GREY"
    if [[ -n "$wifi_network" ]]; then
      label="$wifi_network (no internet)"
    else
      label="No Internet"
    fi
  fi

  # Update SketchyBar item
  apply_instant_change "$NAME" \
    icon="$icon" \
    label="$label" \
    icon.color="$icon_color"
}

# --- Text Scrolling -------------------------------------------------------
set_scroll_state() {
  local target_state="$1"
  local current_state

  current_state=$(get_item_state "$NAME" "geometry.scroll_texts")

  if [[ "$current_state" != "$target_state" ]]; then
    apply_instant_change "$NAME" scroll_texts="$target_state"
  fi
}

# --- Click Handler --------------------------------------------------------
handle_wifi_click() {
  local wifi_port wifi_network

  if [[ "$BUTTON" == "left" ]]; then
    # Left click: Open Control Center WiFi
    if command -v menubar >/dev/null 2>&1; then
      menubar -s "Control Center,WiFi"
    else
      # Fallback: Open Network preferences
      open "x-apple.systempreferences:com.apple.preference.network"
    fi
  else
    # Right click: Toggle WiFi on/off
    wifi_port=$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2}')
    wifi_network=$(ipconfig getsummary "$wifi_port" | awk -F': ' '/ SSID : / {print $2}')

    if [[ -n "$wifi_network" ]]; then
      # WiFi is on, turn it off
      sudo ifconfig "$wifi_port" down 2>/dev/null || networksetup -setairportpower "$wifi_port" off
    else
      # WiFi is off, turn it on
      sudo ifconfig "$wifi_port" up 2>/dev/null || networksetup -setairportpower "$wifi_port" on
    fi

    # Update status after toggle
    sleep 1
    get_wifi_status
  fi
}

# --- Event Handler --------------------------------------------------------
case "$SENDER" in
  "mouse.entered")
    set_scroll_state "on"
    handle_mouse_event "$NAME" "$SENDER"
    ;;
  "mouse.exited")
    set_scroll_state "off"
    handle_mouse_event "$NAME" "$SENDER"
    ;;
  "mouse.clicked")
    handle_mouse_event "$NAME" "$SENDER"
    handle_wifi_click
    ;;
  "wifi_change"|*)
    get_wifi_status
    ;;
esac
