#!/bin/bash
# Title         : progress-bar.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/helpers/progress-bar.sh
# ----------------------------------------------------------------------------
# Reusable progress bar generator using existing constants and colors
# shellcheck disable=SC1091

set -euo pipefail

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"

# --- Progress Bar -----------------------------------------------------------
generate_progress_bar() {
    local percentage="$1"
    local bar_length="${2:-10}"

    # Ensure percentage is numeric and within bounds
    percentage=$(printf "%.0f" "${percentage:-0}" 2>/dev/null || echo "0")
    [ "$percentage" -lt 0 ] && percentage=0
    [ "$percentage" -gt 100 ] && percentage=100

    # Calculate filled and empty segments
    local filled=$((percentage * bar_length / 100))
    local empty=$((bar_length - filled))

    # Build progress bar string with better contrast chars
    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="▰"
    done
    for ((i=0; i<empty; i++)); do
        bar+="▱"
    done

    echo "$bar"
}

# --- Health Color -----------------------------------------------------------
get_health_color() {
    local percentage="$1"
    local metric_type="${2:-cpu}"  # cpu, memory, disk, network

    percentage=$(printf "%.0f" "${percentage:-0}" 2>/dev/null || echo "0")

    # Color thresholds vary by metric type
    case "$metric_type" in
        "memory"|"disk")
            # Memory/disk: higher usage is more concerning
            if [ "$percentage" -ge 90 ]; then
                echo "$RED"
            elif [ "$percentage" -ge 75 ]; then
                echo "$ORANGE"
            elif [ "$percentage" -ge 50 ]; then
                echo "$YELLOW"
            else
                echo "$GREEN"
            fi
            ;;
        "network")
            # Network: any activity is good (green), no activity is neutral
            if [ "$percentage" -gt 0 ]; then
                echo "$GREEN"
            else
                echo "$GREY"
            fi
            ;;
        "cpu"|*)
            # CPU: existing logic from graph.sh
            if [ "$percentage" -ge 75 ]; then
                echo "$RED"
            elif [ "$percentage" -ge 50 ]; then
                echo "$ORANGE"
            elif [ "$percentage" -ge 25 ]; then
                echo "$YELLOW"
            elif [ "$percentage" -ge 5 ]; then
                echo "$GREEN"
            else
                echo "$GREY"
            fi
            ;;
    esac
}

# --- Metric Line ------------------------------------------------------------
format_metric_line() {
    local label="$1"
    local percentage="$2"
    local detail="$3"
    local metric_type="${4:-cpu}"

    local bar
    bar=$(generate_progress_bar "$percentage" 10)
    local color
    color=$(get_health_color "$percentage" "$metric_type")

    # Output with colored progress bar and percentage
    printf "%-7s %s%s%s %s%3s%%%s %s" "$label" "$color" "$bar" "$WHITE" "$color" "$percentage" "$WHITE" "$detail"
}

# --- Main Entry Point -------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Example usage when called directly
    format_metric_line "CPU" "75" "Chrome" "cpu"
fi
