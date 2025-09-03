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
  local system_data rssi signal_percent signal_quality signal_color signal_icon

  # Extract RSSI from system_profiler output (more reliable than wdutil)
  system_data="$1"
  rssi=$(echo "$system_data" | awk '/Signal \/ Noise:/ {gsub(/dBm.*/, "", $4); print $4}')

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
  local wifi_port wifi_network hotspot ip_address public_ip system_info
  local icon icon_color signal_data signal_percent signal_icon signal_quality signal_color
  local channel_info band_suffix

  # Get WiFi hardware port
  wifi_port=$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2}')

  # Robust network detection with rich data extraction
  system_info=$(system_profiler SPAirPortDataType 2>/dev/null)

  # Method 1: system_profiler (primary - richest data with band info)
  if wifi_network=$(echo "$system_info" | awk '/Current Network Information:/{found=1; next} found && /:$/{gsub(/:$/, ""); gsub(/^[[:space:]]*/, ""); print; exit}' 2>/dev/null) && [[ -n "$wifi_network" ]]; then
    # Extract band information from channel data
    channel_info=$(echo "$system_info" | awk '/Channel:/ {print $2 " " $3; exit}')

  # Method 2: ipconfig fallback
  elif wifi_network=$(ipconfig getsummary "$wifi_port" 2>/dev/null | awk '/SSID/ {print $3; exit}') && [[ -n "$wifi_network" ]]; then
    channel_info=""

  # Method 3: networksetup fallback
  elif wifi_network=$(networksetup -getairportnetwork "$wifi_port" 2>/dev/null | cut -d' ' -f4-) && [[ -n "$wifi_network" && "$wifi_network" != "You are not associated with an AirPort network." ]]; then
    channel_info=""

  # Method 4: Permission/connection detection
  else
    wifi_network=""
    channel_info=""
  fi

  # Determine band suffix from channel info (for popup display)
  if [[ "$channel_info" =~ 6GHz ]]; then
    band_suffix="⁶"
  elif [[ "$channel_info" =~ 5GHz ]]; then
    band_suffix="⁵"
  elif [[ "$channel_info" =~ 2GHz ]]; then
    band_suffix="²"
  else
    band_suffix=""
  fi

  # Get hotspot and IP info
  hotspot=$(ipconfig getsummary "$wifi_port" | grep sname | awk '{print $3}')
  ip_address=$(scutil --nwi | grep address | sed 's/.*://' | tr -d ' ' | head -1)

  # Check internet connectivity
  public_ip=1
  if curl -m 2 https://ipinfo.io >/dev/null 2>&1; then
    public_ip=0
  fi

  # Get signal strength data from system_profiler
  signal_data=$(get_signal_strength "$system_info")
  IFS='|' read -r signal_percent signal_icon signal_quality signal_color <<< "$signal_data"

  # Set icon and color based on WiFi state (icon-only display)
  if [[ -n "$hotspot" ]]; then
    # Personal Hotspot active
    icon="$WIFI_HOTSPOT"
    icon_color="$CYAN"
  elif [[ -n "$wifi_network" ]]; then
    # Connected to WiFi network - show signal strength via icon
    if [[ $signal_percent -gt 0 ]]; then
      icon="$signal_icon"
      icon_color="$signal_color"
    else
      icon="$WIFI_SIGNAL_3"
      icon_color="$GREEN"
    fi
  elif [[ -n "$ip_address" ]]; then
    # Has IP but no network name
    icon="$WIFI_SIGNAL_3"
    icon_color="$PINK"
  else
    # No WiFi connection
    icon="$WIFI_OFF"
    icon_color="$RED"
  fi

  # Handle no internet access
  if [[ $public_ip != "0" && "$icon" != "$WIFI_OFF" ]]; then
    icon="$WIFI_ERROR"
    icon_color="$GREY"
  fi

  # Update SketchyBar item (icon-only)
  apply_instant_change "$NAME" \
    icon="$icon" \
    icon.color="$icon_color"
}

# --- WiFi Information Popup ----------------------------------------------
show_wifi_popup() {
  local popup_info popup_details band_text

  # Build comprehensive popup information
  if [[ -n "$hotspot" ]]; then
    popup_info="Personal Hotspot: $hotspot"
  elif [[ -n "$wifi_network" ]]; then
    popup_info="Connected to: $wifi_network$band_suffix"
    
    # Add signal details if available
    if [[ $signal_percent -gt 0 ]]; then
      popup_details="Signal: ${signal_percent}% ($signal_quality)"
    fi
    
    # Add band information if available
    if [[ -n "$channel_info" ]]; then
      # Extract just the band part (e.g., "5GHz" from "56 (5GHz,")
      band_text=$(echo "$channel_info" | sed 's/.*(\([0-9.]*GHz\).*/\1/')
      if [[ -n "$popup_details" ]]; then
        popup_details="$popup_details • $band_text"
      else
        popup_details="Band: $band_text"
      fi
    fi
    
    if [[ -n "$popup_details" ]]; then
      popup_info="$popup_info\n$popup_details"
    fi
    
    # Add internet status if no connectivity
    if [[ $public_ip != "0" ]]; then
      popup_info="$popup_info\n⚠️ No Internet Connection"
    fi
  elif [[ -n "$ip_address" ]]; then
    popup_info="Connected (network name unavailable)"
  else
    popup_info="WiFi: Offline"
    return  # No point showing menu when offline
  fi

  # Show native macOS dialog with options
  local choice
  choice=$(/usr/bin/osascript << EOF
    display dialog "$popup_info" buttons {"Control Center", "Select Network", "Cancel"} default button "Cancel" with title "WiFi Status"
    button returned of result
EOF
  2>/dev/null)
  
  case "$choice" in
    "Control Center")
      if command -v menubar >/dev/null 2>&1; then
        menubar -s "Control Center,WiFi"
      else
        open "x-apple.systempreferences:com.apple.preference.network"
      fi
      ;;
    "Select Network")
      handle_network_selection
      ;;
  esac
}

# --- Network Selection Handler -------------------------------------------
handle_network_selection() {
  local wifi_port networks network_choice

  wifi_port=$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2}')

  # Get preferred networks list
  networks=$(networksetup -listpreferredwirelessnetworks "$wifi_port" 2>/dev/null | tail -n +2 | sed 's/^[[:space:]]*//')

  if [[ -z "$networks" ]]; then
    # No preferred networks found
    /usr/bin/osascript -e 'display alert "No WiFi Networks" message "No preferred networks found. Use System Settings to add networks." buttons {"OK"} default button "OK"' >/dev/null 2>&1
    return
  fi

  # Create network selection menu using native macOS chooser
  network_choice=$(/usr/bin/osascript << EOF
    set networkList to paragraphs of "$networks"
    set chosenNetwork to choose from list networkList with prompt "Select WiFi Network:" with title "WiFi Networks"
    if chosenNetwork is not false then
      return item 1 of chosenNetwork
    else
      return ""
    end if
EOF
  2>/dev/null)

  # Connect to selected network if user made a choice
  if [[ -n "$network_choice" && "$network_choice" != "false" ]]; then
    # Attempt connection
    networksetup -setairportnetwork "$wifi_port" "$network_choice" 2>/dev/null

    # Brief pause for connection attempt
    sleep 2

    # Refresh status display
    get_wifi_status
  fi
}

# --- Click Handler --------------------------------------------------------
handle_wifi_click() {
  local wifi_port wifi_network

  case "$BUTTON" in
    "left")
      # Left click: Show rich information popup with actions
      show_wifi_popup
      ;;
    "right")
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
      ;;
  esac
}

# --- Event Handler --------------------------------------------------------
case "$SENDER" in
  "mouse.entered")
    handle_mouse_event "$NAME" "$SENDER"
    ;;
  "mouse.exited")
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
