#!/bin/bash
# Title         : graph.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/graph.sh
# ----------------------------------------------------------------------------
# System monitoring with CPU, memory, and disk usage popup display
# shellcheck disable=SC1091

set -euo pipefail

# --- Configuration --------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/helpers/progress-bar.sh"

# --- Data Collection -------------------------------------------------------
collect_system_data() {
    # Single top call for CPU and memory data
    local top_output
    top_output=$(top -l1 -n1)

    # Extract CPU percentage
    CPU_PERCENT=$(echo "$top_output" | awk '/^CPU usage:/ {gsub(/%/,"",$3); print $3}')

    # Extract memory data from same top output
    local mem_line
    mem_line=$(echo "$top_output" | grep "^PhysMem:")
    MEMORY_USED=$(echo "$mem_line" | awk '{print $2}' | sed 's/[MG]$//')
    MEMORY_TOTAL=$(echo "$mem_line" | awk '{print $6}' | sed 's/[MG]$//')
    MEMORY_PERCENT=$(bc <<<"scale=0; $MEMORY_USED * 100 / $MEMORY_TOTAL" 2>/dev/null || echo "0")

    # Single ps call for top process
    local probe
    probe=$(/bin/ps -Aceo pid,pcpu,comm -r | awk 'NR==2')
    TOP_PERCENT=$(echo "$probe" | awk '{print $2}')
    TOP_PROCESS=$(echo "$probe" | awk '{print $3}')
    TOP_PID=$(echo "$probe" | awk '{print $1}')

    # Batch remaining metrics
    {
        # Disk usage
        DISK_DATA=$(df -h / | tail -1)
        DISK_PERCENT=$(echo "$DISK_DATA" | awk '{gsub(/%/,"",$5); print $5}')
        DISK_AVAIL=$(echo "$DISK_DATA" | awk '{print $4}')

        # Network activity
        NETWORK_ACTIVITY=$(netstat -ibn | awk 'FNR==4{print ($7+$10)/1024/1024}' 2>/dev/null || echo "0")
        NETWORK_PERCENT=$(bc <<<"scale=0; if($NETWORK_ACTIVITY > 0) 25 else 0" 2>/dev/null || echo "0")

        # Power consumption
        POWER_WATTS=$(macmon pipe -s 1 -i 1 2>/dev/null | jq -r .sys_power 2>/dev/null || echo "0")
        POWER_PERCENT=$(bc <<<"scale=0; $POWER_WATTS * 100 / 30" 2>/dev/null || echo "0")
    }

    # Ensure bounds
    [[ $MEMORY_PERCENT -gt 100 ]] && MEMORY_PERCENT=100
    [[ $POWER_PERCENT -gt 100 ]] && POWER_PERCENT=100
}

# --- Graph Display --------------------------------------------------------
update_main_graph() {
    local graphpoint
    graphpoint=$(bc <<<"scale=1; $CPU_PERCENT / 100 ")

    # CPU color based on load
    local graph_color
    case $(printf "%.0f" "$CPU_PERCENT") in
        [8-9][0-9] | 7[5-9] | 100) graph_color="$RED" ;;
        [5-6][0-9] | 7[0-4]) graph_color="$ORANGE" ;;
        [3-5][0-9] | 2[5-9]) graph_color="$YELLOW" ;;
        [5-9] | 1[0-9] | 2[0-4]) graph_color="$GREEN" ;;
        *) graph_color="$GREY" ;;
    esac

    # Label color for top process
    local label_color
    if [[ $(printf "%.0f" "$TOP_PERCENT") -gt 100 ]]; then
        label_color="$RED"
    else
        label_color="$LIGHT_GREY"
    fi

    # Update graph
    sketchybar --push "$NAME" "$graphpoint" \
        --set "$NAME.percent" label="$(printf "%.0f" "$CPU_PERCENT")%" \
        --set "$NAME" graph.color="$graph_color"

    # Update label
    local graphlabel
    graphlabel="${TOP_PERCENT}% - $TOP_PROCESS [$TOP_PID] | $(printf '%.1f' "$POWER_WATTS")W"
    sketchybar --set "$NAME.label" label="$graphlabel" label.color="$label_color"
}

# --- Popup Updates --------------------------------------------------------
update_popup_metrics() {

    # Check if popup exists
    if sketchybar --query "$NAME.cpu" >/dev/null 2>&1; then
        # CPU line
        local cpu_line
        cpu_line=$(format_metric_line "CPU" "$CPU_PERCENT" "$TOP_PROCESS" "cpu")
        sketchybar --set "$NAME.cpu" label="$cpu_line"

        # Memory line
        local mem_line
        mem_line=$(format_metric_line "Memory" "$MEMORY_PERCENT" "${MEMORY_USED}M used" "memory")
        sketchybar --set "$NAME.memory" label="$mem_line"

        # Disk line
        local disk_line
        disk_line=$(format_metric_line "Disk" "$DISK_PERCENT" "$DISK_AVAIL avail" "disk")
        sketchybar --set "$NAME.disk" label="$disk_line"

        # Network line
        local net_line
        net_line=$(format_metric_line "Network" "$NETWORK_PERCENT" "$(printf '%.1f' "$NETWORK_ACTIVITY")MB/s" "network")
        sketchybar --set "$NAME.network" label="$net_line"

        # Power line
        local power_line
        power_line=$(format_metric_line "Power" "$POWER_PERCENT" "$(printf '%.1f' "$POWER_WATTS")W" "cpu")
        sketchybar --set "$NAME.power" label="$power_line"
    fi
}

# --- Main Execution -------------------------------------------------------
collect_system_data
update_main_graph
update_popup_metrics
