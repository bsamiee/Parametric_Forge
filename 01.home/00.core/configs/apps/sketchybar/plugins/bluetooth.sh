#!/bin/bash
# Title         : bluetooth.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/bluetooth.sh
# ----------------------------------------------------------------------------
# Bluetooth status monitor with device management, battery levels, and Control Center integration
# shellcheck disable=SC1091

# --- Configuration --------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Performance Cache ----------------------------------------------------
BATTERY_CACHE_FILE="/tmp/sketchybar_bluetooth_battery_cache"
BATTERY_CACHE_DURATION=30  # Cache battery info for 30 seconds

# --- Battery Detection Functions -------------------------------------------
get_apple_mouse_battery() {
  ioreg -c AppleBluetoothHIDMouse | awk '/BatteryPercent/ {gsub(/[^0-9]/, "", $NF); print $NF; exit}'
}

get_apple_keyboard_battery() {
  ioreg -c AppleBluetoothHIDKeyboard | awk '/BatteryPercent/ {gsub(/[^0-9]/, "", $NF); print $NF; exit}'
}

get_headphone_battery() {
  # Try multiple methods for headphone battery detection
  local battery_percent

  # Method 1: system_profiler for AirPods and compatible devices
  battery_percent=$(system_profiler SPBluetoothDataType 2>/dev/null | awk '
    /Battery Level:/ {
      gsub(/%/, "", $3)
      if ($3 ~ /^[0-9]+$/) {
        print $3
        exit
      }
    }
  ')

  if [[ -n "$battery_percent" ]]; then
    echo "$battery_percent"
    return
  fi

  # Method 2: Alternative ioreg query for audio devices
  battery_percent=$(ioreg -c IOBluetoothDevice | awk '
    /BatteryPercent/ {
      gsub(/[^0-9]/, "", $NF)
      if ($NF ~ /^[0-9]+$/) {
        print $NF
        exit
      }
    }
  ')

  echo "$battery_percent"
}

get_cached_battery_info() {
  local current_time cache_time battery_info

  # Check if cache exists and is fresh
  if [[ -f "$BATTERY_CACHE_FILE" ]]; then
    current_time=$(date +%s)
    cache_time=$(stat -f %m "$BATTERY_CACHE_FILE" 2>/dev/null || echo "0")

    if [[ $((current_time - cache_time)) -lt $BATTERY_CACHE_DURATION ]]; then
      cat "$BATTERY_CACHE_FILE"
      return
    fi
  fi

  # Cache is stale or doesn't exist - refresh
  get_fresh_battery_info
}

get_fresh_battery_info() {
  local mouse_battery keyboard_battery headphone_battery
  local primary_device battery_percent device_icon result

  # Get battery levels from all device types
  mouse_battery=$(get_apple_mouse_battery)
  keyboard_battery=$(get_apple_keyboard_battery)
  headphone_battery=$(get_headphone_battery)

  # Determine primary device and format output
  if [[ -n "$mouse_battery" && "$mouse_battery" -gt 0 ]]; then
    primary_device="Mouse"
    battery_percent="$mouse_battery"
    device_icon="$BLUETOOTH_MOUSE"
  elif [[ -n "$keyboard_battery" && "$keyboard_battery" -gt 0 ]]; then
    primary_device="Keyboard"
    battery_percent="$keyboard_battery"
    device_icon="$BLUETOOTH_KEYBOARD"
  elif [[ -n "$headphone_battery" && "$headphone_battery" -gt 0 ]]; then
    primary_device="Headphones"
    battery_percent="$headphone_battery"
    device_icon="$BLUETOOTH_HEADPHONES"
  fi

  # Format result
  if [[ -n "$primary_device" && -n "$battery_percent" ]]; then
    result="$primary_device $battery_percent%|$device_icon|$battery_percent"
  else
    result=""
  fi

  # Cache the result
  echo "$result" > "$BATTERY_CACHE_FILE" 2>/dev/null
  echo "$result"
}

get_all_devices_with_battery() {
  local mouse_battery keyboard_battery headphone_battery
  local devices_info="" device_line
  
  # Device definitions: battery_function|device_name|device_icon
  local devices=(
    "get_apple_mouse_battery|Mouse|$BLUETOOTH_MOUSE"
    "get_apple_keyboard_battery|Keyboard|$BLUETOOTH_KEYBOARD" 
    "get_headphone_battery|Headphones|$BLUETOOTH_HEADPHONES"
  )
  
  for device_def in "${devices[@]}"; do
    IFS='|' read -r battery_func device_name device_icon <<< "$device_def"
    local battery_level
    battery_level=$("$battery_func")
    
    if [[ -n "$battery_level" && "$battery_level" -gt 0 ]]; then
      local battery_icon
      battery_icon=$(get_battery_icon "$battery_level")
      device_line="$device_icon $device_name $battery_level% $battery_icon"
      
      if [[ -n "$devices_info" ]]; then
        devices_info="$devices_info\n$device_line"
      else
        devices_info="$device_line"
      fi
    fi
  done
  
  echo "$devices_info"
}

get_battery_icon() {
  local percentage="$1"
  
  if [[ "$percentage" -ge 75 ]]; then
    echo "$BATTERY_100"
  elif [[ "$percentage" -ge 50 ]]; then
    echo "$BATTERY_75"
  elif [[ "$percentage" -ge 25 ]]; then
    echo "$BATTERY_50"
  elif [[ "$percentage" -ge 10 ]]; then
    echo "$BATTERY_25"
  else
    echo "$BATTERY_0"
  fi
}

get_all_paired_devices() {
  local paired_output device_line device_id device_name is_connected
  local result_list=""
  
  # Get paired devices output (format: "address - device_name" per line)
  paired_output=$(blueutil --paired 2>/dev/null)
  
  if [[ -z "$paired_output" ]]; then
    echo ""
    return
  fi
  
  # Process each device (avoid subshell issues)
  while IFS= read -r device_line; do
    if [[ -n "$device_line" && "$device_line" =~ ^[a-fA-F0-9:-]{17} ]]; then
      # Extract device ID (MAC address) - first 17 characters
      device_id=$(echo "$device_line" | cut -d' ' -f1)
      # Extract device name - everything after " - "
      device_name=$(echo "$device_line" | sed 's/^[a-fA-F0-9:-]* - //')
      # Check connection status
      is_connected=$(blueutil --is-connected "$device_id" 2>/dev/null)
      
      if [[ -n "$result_list" ]]; then
        result_list="$result_list\n$device_id|$device_name|$is_connected"
      else
        result_list="$device_id|$device_name|$is_connected"
      fi
    fi
  done <<< "$paired_output"
  
  echo "$result_list"
}

toggle_device_connection() {
  local device_id="$1"
  if [[ $(blueutil --is-connected "$device_id" 2>/dev/null) == "1" ]]; then
    blueutil --disconnect "$device_id" 2>/dev/null
  else
    blueutil --connect "$device_id" 2>/dev/null
  fi
}

# --- Bluetooth Status Detection -------------------------------------------
get_bluetooth_status() {
  local bt_power connected_devices device_count battery_data discoverable
  local icon icon_color battery_label device_icon battery_percent

  # Check Bluetooth power state
  bt_power=$(blueutil --power 2>/dev/null)
  discoverable=$(blueutil -d 2>/dev/null)

  if [[ "$bt_power" != "1" ]]; then
    # Bluetooth is OFF
    icon="$BLUETOOTH_OFF"
    icon_color="$GREY"
  else
    # Bluetooth is ON - check for connected devices first (priority over discoverable)
    connected_devices=$(blueutil --connected 2>/dev/null)
    device_count=$(echo "$connected_devices" | grep -c "address" 2>/dev/null || echo "0")

    if [[ $device_count -gt 0 ]]; then
      # Has connected devices - check for battery info
      battery_data=$(get_cached_battery_info)

      if [[ -n "$battery_data" ]]; then
        # Parse battery data: "Device 85%|icon|85"
        IFS='|' read -r battery_label device_icon battery_percent <<< "$battery_data"

        # Set color based on battery level
        if [[ "$battery_percent" -le 15 ]]; then
          icon_color="$RED"
        elif [[ "$battery_percent" -le 30 ]]; then
          icon_color="$ORANGE"
        else
          icon_color="$GREEN"
        fi

        icon="$BLUETOOTH_ON"
      else
        # Connected but no battery info available
        icon="$BLUETOOTH_ON"
        icon_color="$GREEN"
      fi
    elif [[ "$discoverable" == "1" ]]; then
      # Discoverable mode when no devices connected
      icon="$BLUETOOTH_SEARCHING"
      icon_color="$CYAN"
    else
      # Powered on but no devices connected and not discoverable
      icon="$BLUETOOTH_ON"
      icon_color="$CYAN"
    fi
  fi

  # Update SketchyBar display (icon-only)
  apply_instant_change "$NAME" \
    icon="$icon" \
    icon.color="$icon_color"
}

# --- Device Connection Management ------------------------------------------
get_preferred_device() {
  # Get most recently connected device for quick reconnect
  blueutil --recent 2>/dev/null | head -1 | awk '{print $2}' | tr -d ','
}

connect_preferred_device() {
  local preferred_device
  preferred_device=$(get_preferred_device)

  if [[ -n "$preferred_device" ]]; then
    blueutil --connect "$preferred_device" 2>/dev/null
    sleep 2
    get_bluetooth_status
  fi
}

# --- Text Scrolling Control (Legacy - not used in icon-only mode) ------
set_scroll_state() {
  # Function retained for compatibility but not needed in icon-only mode
  return 0
}

# --- Click Handler --------------------------------------------------------
show_bluetooth_popup() {
  local bt_power all_devices popup_info choice
  
  bt_power=$(blueutil --power 2>/dev/null)
  
  if [[ "$bt_power" != "1" ]]; then
    popup_info="Bluetooth: Off"
  else
    all_devices=$(get_all_devices_with_battery)
    
    if [[ -n "$all_devices" ]]; then
      popup_info="Connected Devices:\n$all_devices"
    else
      popup_info="Bluetooth: On\nNo devices with battery info"
    fi
  fi

  # Show native macOS dialog with options
  choice=$(/usr/bin/osascript << EOF
    display dialog "$popup_info" buttons {"Manage Devices", "Control Center", "Cancel"} default button "Cancel" with title "Bluetooth Status"
    button returned of result
EOF
  2>/dev/null)
  
  case "$choice" in
    "Control Center")
      if command -v menubar >/dev/null 2>&1; then
        menubar -s "Control Center,Bluetooth" 2>/dev/null
      else
        open "x-apple.systempreferences:com.apple.preferences.Bluetooth" 2>/dev/null
      fi
      ;;
    "Manage Devices")
      show_device_management_popup
      ;;
  esac
}

show_device_management_popup() {
  local devices_list device_names_array device_choice selected_device
  local device_id device_name is_connected status_text
  
  # Get all paired devices
  devices_list=$(get_all_paired_devices)
  
  if [[ -z "$devices_list" ]]; then
    /usr/bin/osascript -e 'display alert "No Paired Devices" message "No paired Bluetooth devices found. Pair devices in System Settings first." buttons {"OK"} default button "OK"' >/dev/null 2>&1
    return
  fi
  
  # Build device names array for chooser with icon-based status
  device_names_array=""
  while IFS='|' read -r device_id device_name is_connected; do
    if [[ -n "$device_id" ]]; then
      # Get device icon (simplified - could be enhanced with device type detection)
      local device_icon="􀟙"  # Default Bluetooth icon
      
      # Use color to indicate connection status
      if [[ "$is_connected" == "1" ]]; then
        status_text="$device_icon $device_name"
      else
        status_text="$device_icon $device_name"
      fi
      
      if [[ -n "$device_names_array" ]]; then
        device_names_array="$device_names_array\n$status_text"
      else
        device_names_array="$status_text"
      fi
    fi
  done <<< "$devices_list"
  
  # Show device selection dialog
  device_choice=$(/usr/bin/osascript << EOF
    set deviceList to paragraphs of "$device_names_array"
    set chosenDevice to choose from list deviceList with prompt "Select device to toggle connection:" with title "Bluetooth Device Management"
    if chosenDevice is not false then
      return item 1 of chosenDevice
    else
      return ""
    end if
EOF
  2>/dev/null)
  
  # Process selection
  if [[ -n "$device_choice" && "$device_choice" != "false" ]]; then
    # Extract device name from choice (remove icon prefix)
    selected_device=$(echo "$device_choice" | sed 's/^􀟙 //')
    
    # Find device ID and toggle connection
    while IFS='|' read -r device_id device_name is_connected; do
      if [[ "$device_name" == "$selected_device" ]]; then
        toggle_device_connection "$device_id"
        # Brief pause for connection change
        sleep 2
        # Refresh status
        update_bluetooth_status
        break
      fi
    done <<< "$devices_list"
  fi
}

handle_bluetooth_click() {
  local current_power

  case "$BUTTON" in
    "left")
      # Left click: Show rich information popup with multi-device dashboard
      show_bluetooth_popup
      ;;
    "right")
      # Right click: Toggle Bluetooth power
      current_power=$(blueutil --power 2>/dev/null)

      if [[ "$current_power" == "1" ]]; then
        blueutil --power 0 2>/dev/null  # Turn OFF
      else
        blueutil --power 1 2>/dev/null  # Turn ON
      fi

      # Clear battery cache after power toggle
      rm -f "$BATTERY_CACHE_FILE" 2>/dev/null

      # Update status after toggle
      sleep 1
      get_bluetooth_status
      ;;
    "middle")
      # Middle click: Quick connect to most recent device
      connect_preferred_device
      ;;
  esac
}

# --- Connection State Change Detection ------------------------------------
detect_connection_changes() {
  local current_connections previous_connections
  local connection_state_file="/tmp/sketchybar_bluetooth_connections"

  current_connections=$(blueutil --connected 2>/dev/null | sort)
  previous_connections=""

  if [[ -f "$connection_state_file" ]]; then
    previous_connections=$(cat "$connection_state_file" 2>/dev/null)
  fi

  # Update connection state file
  echo "$current_connections" > "$connection_state_file" 2>/dev/null

  # If connections changed, clear battery cache for fresh data
  if [[ "$current_connections" != "$previous_connections" ]]; then
    rm -f "$BATTERY_CACHE_FILE" 2>/dev/null
  fi
}

# --- Enhanced Status Updates with Change Detection ------------------------
update_bluetooth_status() {
  # Detect connection changes first
  detect_connection_changes

  # Update display
  get_bluetooth_status
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
    handle_bluetooth_click
    ;;
  "bluetooth_change"|*)
    update_bluetooth_status
    ;;
esac