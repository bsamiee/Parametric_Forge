#!/bin/bash
# Title         : wifi.sh
# Author        : Bardia Samiee (adapted from reference)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/wifi.sh
# ----------------------------------------------------------------------------
# Consolidated WiFi plugin with live status detection and control
# shellcheck disable=SC1091

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- WiFi Status Detection --------------------------------------------------
get_wifi_status() {
  local wifi_port wifi_network hotspot ip_address public_ip
  local icon icon_color label

  # Get WiFi hardware port
  wifi_port=$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2}')

  # Get current network info
  wifi_network=$(system_profiler SPAirPortDataType | awk '/Current Network/ {getline;$1=$1; gsub(":",""); print;exit}')
  hotspot=$(ipconfig getsummary "$wifi_port" | grep sname | awk '{print $3}')
  ip_address=$(scutil --nwi | grep address | sed 's/.*://' | tr -d ' ' | head -1)

  # Check internet connectivity
  public_ip=1
  if curl -m 2 https://ipinfo.io >/dev/null 2>&1; then
    public_ip=0
  fi

  # Set icon and color based on WiFi state
  if [[ -n "$hotspot" ]]; then
    # Personal Hotspot active
    icon="$WIFI_HOTSPOT"
    icon_color="$PRIMARY_CYAN"
    label="$hotspot"
  elif [[ -n "$wifi_network" ]]; then
    # Connected to WiFi network
    icon="$WIFI_CONNECTED"
    icon_color="$PRIMARY_GREEN"
    label="$wifi_network"
  elif [[ -n "$ip_address" ]]; then
    # Has IP but no network name
    icon="$WIFI_CONNECTED"
    icon_color="$PRIMARY_PINK"
    label="Connected"
  else
    # No WiFi connection
    icon="$WIFI_OFF"
    icon_color="$PRIMARY_RED"
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

# --- Scroll Text Management -------------------------------------------------
set_scroll_state() {
  local target_state="$1"
  local current_state

  current_state=$(get_item_state "$NAME" "geometry.scroll_texts")

  if [[ "$current_state" != "$target_state" ]]; then
    apply_instant_change "$NAME" scroll_texts="$target_state"
  fi
}

# --- Click Handling ---------------------------------------------------------
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

# --- Main Event Handler -----------------------------------------------------
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
