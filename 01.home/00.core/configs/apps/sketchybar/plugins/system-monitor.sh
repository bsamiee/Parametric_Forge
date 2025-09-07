#!/bin/bash
# Title         : system-monitor.sh
# Author        : Parametric Forge
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/system-monitor.sh
# ----------------------------------------------------------------------------
# System monitoring with CPU graph + detailed popup metrics
# shellcheck disable=SC1091

set -euo pipefail

# --- Configuration -----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/helpers/progress-bar.sh"

# --- UI Helpers --------------------------------------------------------------
hover_on() {
  # Highlight the whole group for a cohesive hover effect without toggling drawing
  sketchybar --set system_monitor_group \
    background.color="$FAINT_GREY" \
    background.corner_radius="$RADIUS_MEDIUM" >/dev/null 2>&1 || true
}

hover_off() {
  sketchybar --set system_monitor_group background.color="$TRANSPARENT" >/dev/null 2>&1 || true
}

# --- Network rate state ------------------------------------------------------
NET_STATE_FILE="/tmp/sketchybar_sysmon_net.state"

net_bytes_total() {
  # Sum ibytes+obytes for all non-loopback interfaces
  netstat -ibn 2>/dev/null | awk 'NR>1 && $1!="lo0" && $7 ~ /^[0-9]+$/ && $10 ~ /^[0-9]+$/ {sum += $7 + $10} END {print (sum+0)}'
}

calc_net_rate_mb_s() {
  local now prev_t prev_b curr_b dt db
  now=$(date +%s)
  curr_b=$(net_bytes_total)
  if [[ -r "$NET_STATE_FILE" ]]; then
    read -r prev_t prev_b < "$NET_STATE_FILE" || true
  fi
  echo "$now $curr_b" > "$NET_STATE_FILE" 2>/dev/null || true
  if [[ -n "${prev_t:-}" && -n "${prev_b:-}" && $now -gt ${prev_t:-0} && $curr_b -ge ${prev_b:-0} ]]; then
    dt=$(( now - prev_t ))
    db=$(( curr_b - prev_b ))
    # bytes/sec -> MB/s
    awk -v dbytes="$db" -v dtime="$dt" 'BEGIN { if (dtime<=0) {print 0} else { printf("%.2f\n", (dbytes/dtime)/1024/1024) } }'
  else
    echo "0"
  fi
}

# --- Data Collection ---------------------------------------------------------
collect_system_data() {
  # Single top call for CPU + memory
  local top_output mem_line probe
  top_output=$(top -l1 -n1)

  # CPU percent (user)
  CPU_PERCENT=$(echo "$top_output" | awk '/^CPU usage:/ {gsub(/%,/,"",$3); gsub(/%/,"",$3); print $3}' 2>/dev/null || echo "0")
  [[ -z "$CPU_PERCENT" ]] && CPU_PERCENT=0

  # Memory percent (best-effort from PhysMem line)
  mem_line=$(echo "$top_output" | grep '^PhysMem:' || true)
  if [[ -n "$mem_line" ]]; then
    # Example formats vary; keep previous heuristic (used/total)
    MEMORY_USED=$(echo "$mem_line" | awk '{print $2}' | sed 's/[MG]$//' 2>/dev/null || echo 0)
    MEMORY_TOTAL=$(echo "$mem_line" | awk '{print $6}' | sed 's/[MG]$//' 2>/dev/null || echo 1)
    MEMORY_PERCENT=$(bc <<<"scale=0; $MEMORY_USED * 100 / $MEMORY_TOTAL" 2>/dev/null || echo "0")
  else
    MEMORY_PERCENT=0
    MEMORY_USED=0
  fi

  # Top process (by CPU)
  probe=$(/bin/ps -Aceo pid,pcpu,comm -r | awk 'NR==2')
  TOP_PERCENT=$(echo "$probe" | awk '{print $2}' 2>/dev/null || echo 0)
  TOP_PROCESS=$(echo "$probe" | awk '{print $3}' 2>/dev/null || echo "-")
  TOP_PID=$(echo "$probe" | awk '{print $1}' 2>/dev/null || echo "-")

  # Disk root usage
  DISK_DATA=$(df -h / | tail -1)
  DISK_PERCENT=$(echo "$DISK_DATA" | awk '{gsub(/%/,"",$5); print $5}' 2>/dev/null || echo 0)
  DISK_AVAIL=$(echo "$DISK_DATA" | awk '{print $4}' 2>/dev/null || echo 0)

  # Network activity rate (MB/s)
  NETWORK_ACTIVITY=$(calc_net_rate_mb_s)
  # Preserve original simplistic percent: 25 if any activity, else 0
  NETWORK_PERCENT=$(awk -v v="$NETWORK_ACTIVITY" 'BEGIN { if (v+0>0) print 25; else print 0 }')

  # Power (requires macmon)
  POWER_WATTS=$(macmon pipe -s 1 -i 1 2>/dev/null | jq -r .sys_power 2>/dev/null || echo "0")
  POWER_PERCENT=$(bc <<<"scale=0; $POWER_WATTS * 100 / 30" 2>/dev/null || echo "0")

  # Clamp
  [[ -z "$MEMORY_PERCENT" ]] && MEMORY_PERCENT=0
  [[ -z "$POWER_PERCENT"  ]] && POWER_PERCENT=0
  [[ $MEMORY_PERCENT -gt 100 ]] && MEMORY_PERCENT=100
  [[ $POWER_PERCENT  -gt 100 ]] && POWER_PERCENT=100
}

# --- Main Graph Update -------------------------------------------------------
update_main_graph() {
  local graphpoint graph_color label_color

  # Normalize to 0..1 for graph push
  graphpoint=$(bc <<<"scale=2; $CPU_PERCENT / 100" 2>/dev/null || echo "0.0")

  # Color based on CPU
  case $(printf "%.0f" "$CPU_PERCENT") in
    100|9[0-9]|8[0-9]|7[5-9]) graph_color="$RED" ;;
    7[0-4]|6[0-9]|5[0-9])     graph_color="$ORANGE" ;;
    4[0-9]|3[0-9]|2[5-9])     graph_color="$YELLOW" ;;
    2[0-4]|1[0-9]|[5-9])      graph_color="$GREEN" ;;
    *)                        graph_color="$GREY" ;;
  esac

  # Label color based on top proc percent
  if [[ $(printf "%.0f" "${TOP_PERCENT:-0}") -gt 100 ]]; then
    label_color="$RED"
  else
    label_color="$LIGHT_GREY"
  fi

  # Update graph + percent + status label
  sketchybar \
    --push "$NAME" "$graphpoint" \
    --set "$NAME" graph.color="$graph_color" \
    --set "$NAME.percent" label="$(printf "%.0f" "$CPU_PERCENT")%" \
    --set "$NAME.label" label="${TOP_PERCENT}% - ${TOP_PROCESS} [${TOP_PID}] | $(printf '%.1f' "$POWER_WATTS")W" label.color="$label_color"
}

# --- Popup Update ------------------------------------------------------------
update_popup_metrics() {
  # Build rows: one color per row, not inline color codes
  local bar color text

  # CPU
  bar=$(generate_progress_bar "$CPU_PERCENT" 10)
  color=$(get_health_color "$CPU_PERCENT" cpu)
  text=$(printf "%-7s %s %3s%% %s" "CPU" "$bar" "$(printf '%.0f' "$CPU_PERCENT")" "$TOP_PROCESS")
  sketchybar --set "$NAME.cpu" label="$text" label.color="$color"

  # Memory
  bar=$(generate_progress_bar "$MEMORY_PERCENT" 10)
  color=$(get_health_color "$MEMORY_PERCENT" memory)
  text=$(printf "%-7s %s %3s%% %s" "Memory" "$bar" "$(printf '%.0f' "$MEMORY_PERCENT")" "${MEMORY_USED}M used")
  sketchybar --set "$NAME.memory" label="$text" label.color="$color"

  # Disk
  bar=$(generate_progress_bar "$DISK_PERCENT" 10)
  color=$(get_health_color "$DISK_PERCENT" disk)
  text=$(printf "%-7s %s %3s%% %s" "Disk" "$bar" "$(printf '%.0f' "$DISK_PERCENT")" "$DISK_AVAIL avail")
  sketchybar --set "$NAME.disk" label="$text" label.color="$color"

  # Network
  bar=$(generate_progress_bar "$NETWORK_PERCENT" 10)
  color=$(get_health_color "$NETWORK_PERCENT" network)
  text=$(printf "%-7s %s %s %s" "Network" "$bar" "$(printf '%.1f' "$NETWORK_ACTIVITY")MB/s" "")
  sketchybar --set "$NAME.network" label="$text" label.color="$color"

  # Power
  bar=$(generate_progress_bar "$POWER_PERCENT" 10)
  color=$(get_health_color "$POWER_PERCENT" cpu)
  text=$(printf "%-7s %s %s %s" "Power" "$bar" "$(printf '%.1f' "$POWER_WATTS")W" "")
  sketchybar --set "$NAME.power" label="$text" label.color="$color"
}

# --- Event Handling ----------------------------------------------------------
case "${SENDER:-}" in
  mouse.entered)
    # Hover for any member of the group
    case "$NAME" in
      system_monitor|system_monitor.percent|system_monitor.label) hover_on ;;
    esac
    ;;
  mouse.exited)
    case "$NAME" in
      system_monitor|system_monitor.percent|system_monitor.label) hover_off ;;
    esac
    ;;
  mouse.clicked)
    # Toggle handled by click_script; do an immediate refresh for snappy UI
    NAME="system_monitor"
    collect_system_data
    update_main_graph
    update_popup_metrics
    ;;
  system_woke)
    NAME="system_monitor"
    collect_system_data
    update_main_graph
    update_popup_metrics
    ;;
  *)
    # Regular refresh path
    if [[ "$NAME" == "system_monitor" ]]; then
      collect_system_data
      update_main_graph
      update_popup_metrics
    else
      # If called unexpectedly for subitems, just refresh via main
      NAME="system_monitor"
      collect_system_data
      update_main_graph
      update_popup_metrics
    fi
    ;;
esac
