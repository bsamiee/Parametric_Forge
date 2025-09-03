#!/bin/bash
# Title         : battery.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/battery.sh
# ----------------------------------------------------------------------------
# Advanced battery management plugin with AlDente-like functionality
# shellcheck disable=SC1091

set -euo pipefail

source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Battery Data Collection ------------------------------------------------
get_battery_percentage() {
    pmset -g batt | grep -Eo "\d+%" | cut -d% -f1 || echo "0"
}

get_charging_status() {
    pmset -g batt | grep -q 'AC Power' && echo "charging" || echo "discharging"
}

get_time_remaining() {
    local time_info
    time_info=$(pmset -g batt | grep -o "[0-9]*:[0-9]*" | head -1)
    [[ -n "$time_info" ]] && echo "$time_info" || echo "N/A"
}

get_battery_health() {
    if command -v system_profiler &> /dev/null; then
        local cycle_count design_capacity current_capacity
        cycle_count=$(system_profiler SPPowerDataType | grep -i "cycle count" | awk '{print $3}' | head -1 || echo "N/A")
        design_capacity=$(system_profiler SPPowerDataType | grep -i "full charge capacity" | awk '{print $4}' | head -1 || echo "0")
        current_capacity=$(system_profiler SPPowerDataType | grep -i "full charge capacity" | awk '{print $4}' | head -1 || echo "0")

        if [[ "$design_capacity" != "0" && "$design_capacity" != "N/A" ]]; then
            local health_percent
            health_percent=$(echo "scale=0; $current_capacity*100/$design_capacity" | bc 2>/dev/null || echo "N/A")
            echo "${health_percent}% (${cycle_count} cycles)"
        else
            echo "N/A"
        fi
    else
        echo "N/A"
    fi
}

get_charge_limit_status() {
    if command -v battery &> /dev/null; then
        local status
        status=$(battery status 2>/dev/null | grep -o "maintain [0-9]*" | cut -d' ' -f2 2>/dev/null || echo "")
        [[ -n "$status" ]] && echo "$status" || echo "off"
    else
        echo "unavailable"
    fi
}

get_adapter_status() {
    if command -v battery &> /dev/null; then
        battery status 2>/dev/null | grep -q "adapter.*off" && echo "off" || echo "on"
    else
        echo "unknown"
    fi
}

get_battery_temperature() {
    if command -v system_profiler &> /dev/null; then
        system_profiler SPPowerDataType | grep -i temperature | awk '{print $2 " " $3}' | head -1 || echo "N/A"
    else
        echo "N/A"
    fi
}

# --- Visual State Management -----------------------------------------------
get_battery_icon() {
    local percentage="$1"
    local charging="$2"

    if [[ "$charging" == "charging" ]]; then
        echo "$BATTERY_CHARGING"
    elif (( percentage <= 20 )); then
        echo "$BATTERY_0"
    elif (( percentage <= 40 )); then
        echo "$BATTERY_25"
    elif (( percentage <= 60 )); then
        echo "$BATTERY_50"
    elif (( percentage <= 80 )); then
        echo "$BATTERY_75"
    else
        echo "$BATTERY_100"
    fi
}

get_battery_color() {
    local percentage="$1"
    local charging="$2"
    local limit_status="$3"
    local adapter_status="${4:-on}"
    
    # Adapter disabled (sailing mode)
    if [[ "$adapter_status" == "off" ]]; then
        echo "$PURPLE"   # Forced discharge mode
    # Charging state colors
    elif [[ "$charging" == "charging" ]]; then
        if [[ "$limit_status" != "off" && "$limit_status" != "unavailable" ]]; then
            echo "$CYAN"  # Charging with limit
        else
            echo "$GREEN"  # Normal charging
        fi
    # Battery level colors
    elif (( percentage <= 15 )); then
        echo "$RED"      # Critical
    elif (( percentage <= 30 )); then
        echo "$ORANGE"   # Low
    elif (( percentage <= 50 )); then
        echo "$YELLOW"   # Medium
    else
        echo "$WHITE"    # Good
    fi
}

# --- Charge Limiting Functions ----------------------------------------------
# Battery control functions using research-based patterns
set_charge_limit() {
    local limit="${1:-80}"
    if ! command -v battery &> /dev/null; then
        sketchybar --set "$NAME" label="❌ CLI not found"
        return 1
    fi
    
    if [[ "$limit" == "100" ]]; then
        battery maintain stop &> /dev/null
    else
        battery maintain "$limit" &> /dev/null
    fi
    update_battery_display
}

toggle_adapter() {
    if ! command -v battery &> /dev/null; then
        sketchybar --set "$NAME" label="❌ CLI not found"
        return 1
    fi
    
    local adapter_status
    adapter_status=$(get_adapter_status)
    
    if [[ "$adapter_status" == "off" ]]; then
        battery adapter on &> /dev/null
    else
        battery adapter off &> /dev/null
    fi
    update_battery_display
}

calibrate_battery() {
    if ! command -v battery &> /dev/null; then
        sketchybar --set "$NAME" label="❌ Battery CLI not found"
        return 1
    fi
    
    sketchybar --set "$NAME" label="Calibrating..."
    battery calibrate &> /dev/null &
    
    # Return to normal display after brief feedback
    sleep 2
    update_battery_display
}

# --- Display Updates -------------------------------------------------------
update_battery_display() {
    local percentage charging time_remaining icon color limit_status adapter_status
    
    percentage=$(get_battery_percentage)
    charging=$(get_charging_status)
    time_remaining=$(get_time_remaining)
    limit_status=$(get_charge_limit_status)
    adapter_status=$(get_adapter_status)
    
    icon=$(get_battery_icon "$percentage" "$charging")
    color=$(get_battery_color "$percentage" "$charging" "$limit_status" "$adapter_status")
    
    # Main display with adapter status
    local label="${percentage}%"
    if [[ "$adapter_status" == "off" ]]; then
        label="${percentage}% 🔌🚫"
    elif [[ "$limit_status" != "off" && "$limit_status" != "unavailable" ]]; then
        label="${percentage}% (${limit_status}%)"
    fi
    
    sketchybar --set "$NAME" \
        icon="$icon" \
        icon.color="$color" \
        label="$label" \
        label.color="$color"
    
    update_popup_items
}

update_popup_items() {
    local percentage charging time_remaining health temp limit_status adapter_status
    
    percentage=$(get_battery_percentage)
    charging=$(get_charging_status)
    time_remaining=$(get_time_remaining)
    health=$(get_battery_health)
    temp=$(get_battery_temperature)
    limit_status=$(get_charge_limit_status)
    adapter_status=$(get_adapter_status)
    
    # Battery details
    local status_text="$percentage% • $charging"
    [[ "$time_remaining" != "N/A" ]] && status_text="$status_text • $time_remaining remaining"
    [[ "$temp" != "N/A" ]] && status_text="$status_text • $temp"
    [[ "$adapter_status" == "off" ]] && status_text="$status_text • Adapter OFF"
    
    sketchybar --set battery.details label="$status_text"
    
    # Battery health
    sketchybar --set battery.health label="Health: $health"
    
    # Control options
    local limit_text
    if [[ "$limit_status" == "unavailable" ]]; then
        limit_text="Battery CLI not installed"
    elif [[ "$limit_status" == "off" ]]; then
        limit_text="Click: Limit | ⌥Click: Adapter"
    else
        limit_text="${limit_status}% Limit • Click: Disable"
    fi
    
    sketchybar --set battery.limit label="$limit_text"
}

# --- Mouse Event Handlers --------------------------------------------------
handle_click() {
    local event="$1"
    
    case "$event" in
        "mouse.clicked")
            sketchybar --set battery popup.drawing=toggle
            ;;
        "mouse.entered")
            apply_visual_state "$NAME" "hover"
            ;;
        "mouse.exited")
            apply_visual_state "$NAME" "default"
            ;;
    esac
}

# --- Main Execution Logic --------------------------------------------------
case "${1:-update}" in
    "limit")
        set_charge_limit "${2:-80}"
        ;;
    "adapter")
        toggle_adapter
        ;;
    "calibrate")
        calibrate_battery
        ;;
    "mouse.clicked"|"mouse.entered"|"mouse.exited")
        handle_click "$1"
        ;;
    *)
        update_battery_display
        ;;
esac