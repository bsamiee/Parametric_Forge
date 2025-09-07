#!/bin/bash
# Title         : wifi.sh
# Author        : Parametric Forge
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/wifi.sh
# ----------------------------------------------------------------------------
# Wi‑Fi status + preferred networks popup in SketchyBar style
# Proper separation, hover effects, and minimal polling.
# shellcheck disable=SC1091

set -euo pipefail

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- UI Hover Helpers -------------------------------------------------------
set_item() { local item="$1"; shift; sketchybar --set "$item" "$@" 2>/dev/null || true; }
hover_on()  { set_item "$1" background.drawing=on  background.color="$FAINT_GREY"; }
hover_off() { set_item "$1" background.drawing=off background.color="$TRANSPARENT"; }

# --- Paths / State ----------------------------------------------------------
PREF_MAP_FILE="/tmp/sketchybar_wifi_pref_map"    # slot|ssid

# --- Wi‑Fi Helpers ----------------------------------------------------------
wifi_port() {
  networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2; exit}'
}

wifi_power_get() {
  local port; port=$(wifi_port)
  networksetup -getairportpower "$port" 2>/dev/null | awk '{print $NF}' | tr '[:upper:]' '[:lower:]'
}

wifi_power_toggle() {
  local port p; port=$(wifi_port); p=$(wifi_power_get)
  if [[ "$p" == "on" ]]; then
    networksetup -setairportpower "$port" off >/dev/null 2>&1 || true
  else
    networksetup -setairportpower "$port" on  >/dev/null 2>&1 || true
  fi
}

wifi_current_ssid() {
  # Prefer airport -I to avoid macOS 15 network permission flakiness
  local ap ssid port out
  ap=$(airport_info)
  if [[ -n "$ap" ]]; then
    ssid=$(echo "$ap" | awk -F': ' '/ SSID/ {print $2; exit}')
    echo "${ssid:-}"
    return
  fi
  port=$(wifi_port)
  out=$(networksetup -getairportnetwork "$port" 2>/dev/null || true)
  if echo "$out" | grep -q 'You are not associated'; then
    echo ""
  else
    echo "$out" | sed 's/^Current Wi-Fi Network: //'
  fi
}

airport_bin() {
  echo "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
}

airport_info() {
  local bin; bin=$(airport_bin)
  if [[ -x "$bin" ]]; then
    "$bin" -I 2>/dev/null || true
  fi
}

wifi_system_info() {
  # Fallback full info (slower)
  system_profiler SPAirPortDataType 2>/dev/null || true
}

wifi_signal_from_sysinfo() {
  # Echo: percent|icon|quality|color
  local info="$1" rssi pct quality color icon
  rssi=$(echo "$info" | awk '/Signal \/ Noise:/ {gsub(/dBm.*/, "", $4); print $4; exit}')
  if [[ -z "$rssi" || "$rssi" == "0" ]]; then
    echo "0|$WIFI_SIGNAL_3|Unknown|$GREY"; return
  fi
  pct=$(awk -v r="$rssi" 'BEGIN{p=((r+100)/70)*100; if(p<0)p=0; if(p>100)p=100; printf("%d", p+0.5)}')
  if (( pct >= 70 )); then quality="Excellent"; color="$GREEN";  icon="$WIFI_SIGNAL_3";
  elif (( pct >= 40 )); then quality="Good";      color="$YELLOW"; icon="$WIFI_SIGNAL_2";
  elif (( pct >= 10 )); then quality="Fair";      color="$ORANGE"; icon="$WIFI_SIGNAL_1";
  else                    quality="Weak";      color="$RED";    icon="$WIFI_SIGNAL_1"; fi
  echo "$pct|$icon|$quality|$color"
}

wifi_signal_from_airport() {
  # Echo: percent|icon|quality|color using airport -I (fast)
  local info="$1" rssi pct quality color icon
  rssi=$(echo "$info" | awk -F': ' '/agrCtlRSSI/ {print $2; exit}')
  if [[ -z "$rssi" ]]; then
    echo "0|$WIFI_SIGNAL_3|Unknown|$GREY"; return
  fi
  pct=$(awk -v r="$rssi" 'BEGIN{p=((r+100)/70)*100; if(p<0)p=0; if(p>100)p=100; printf("%d", p+0.5)}')
  if (( pct >= 70 )); then quality="Excellent"; color="$GREEN";  icon="$WIFI_SIGNAL_3";
  elif (( pct >= 40 )); then quality="Good";      color="$YELLOW"; icon="$WIFI_SIGNAL_2";
  elif (( pct >= 10 )); then quality="Fair";      color="$ORANGE"; icon="$WIFI_SIGNAL_1";
  else                    quality="Weak";      color="$RED";    icon="$WIFI_SIGNAL_1"; fi
  echo "$pct|$icon|$quality|$color"
}

wifi_band_suffix_from_sysinfo() {
  local info="$1" ch band
  ch=$(echo "$info" | awk '/Channel:/ {for(i=1;i<=NF;i++) printf $i" "; print ""; exit}')
  if echo "$ch" | grep -q '6GHz'; then echo "⁶"; return; fi
  if echo "$ch" | grep -q '5GHz'; then echo "⁵"; return; fi
  if echo "$ch" | grep -q '2';    then echo "²"; return; fi
  echo ""
}

wifi_band_suffix_from_airport() {
  local info="$1" ch
  # airport prints: "channel: 149,80" or "channel: 1" etc.
  ch=$(echo "$info" | awk -F': ' '/channel/{print $2; exit}' | awk -F',' '{print $1}' | tr -d ' ')
  [[ -z "$ch" ]] && { echo ""; return; }
  # 2.4GHz channels 1-14; 5GHz commonly 36-165; 6GHz often > 180
  if [[ "$ch" =~ ^[0-9]+$ ]]; then
    if (( ch >= 1 && ch <= 14 )); then echo "²"; return; fi
    if (( ch >= 36 && ch <= 165 )); then echo "⁵"; return; fi
    if (( ch > 165 )); then echo "⁶"; return; fi
  fi
  echo ""
}

wifi_hotspot_name() {
  local port; port=$(wifi_port)
  ipconfig getsummary "$port" 2>/dev/null | awk '/sname/ {print $3; exit}'
}

wifi_ip_addr() {
  # IP for the Wi‑Fi interface only
  local port; port=$(wifi_port)
  ipconfig getifaddr "$port" 2>/dev/null || true
}

has_internet() {
  # 0 = online, 1 = offline; cheap 204 endpoint
  xh --timeout 2s --quiet https://connectivitycheck.gstatic.com/generate_204 >/dev/null 2>&1
}

preferred_networks() {
  local port; port=$(wifi_port)
  networksetup -listpreferredwirelessnetworks "$port" 2>/dev/null | tail -n +2 | sed 's/^\s*//'
}

connect_network() {
  local ssid="$1" port; port=$(wifi_port)
  networksetup -setairportnetwork "$port" "$ssid" >/dev/null 2>&1 || true
}

# --- UI Refreshers ----------------------------------------------------------
refresh_main() {
  local info_airport info_sys ssid hotspot ip sig pct icon quality color band online icon_main icon_color
  info_airport=$(airport_info)
  info_sys=""
  ssid=$(wifi_current_ssid)
  hotspot=$(wifi_hotspot_name)
  ip=$(wifi_ip_addr)
  if [[ -n "$info_airport" ]]; then
    read -r pct icon quality color < <(wifi_signal_from_airport "$info_airport" | tr '|' ' ')
    band=$(wifi_band_suffix_from_airport "$info_airport")
  else
    info_sys=$(wifi_system_info)
    read -r pct icon quality color < <(wifi_signal_from_sysinfo "$info_sys" | tr '|' ' ')
    band=$(wifi_band_suffix_from_sysinfo "$info_sys")
  fi
  online=1; has_internet && online=0 || online=1

  if [[ -n "$hotspot" ]]; then
    icon_main="$WIFI_HOTSPOT"; icon_color="$CYAN"
  elif [[ -n "$ssid" ]]; then
    if (( pct > 0 )); then icon_main="$icon"; icon_color="$color"; else icon_main="$WIFI_SIGNAL_3"; icon_color="$GREEN"; fi
  elif [[ -n "$ip" ]]; then
    icon_main="$WIFI_SIGNAL_3"; icon_color="$PINK"
  else
    icon_main="$WIFI_OFF"; icon_color="$RED"
  fi

  if (( online != 0 )) && [[ "$icon_main" != "$WIFI_OFF" ]]; then
    icon_main="$WIFI_ERROR"; icon_color="$GREY"
  fi

  set_item wifi icon="$icon_main" icon.color="$icon_color"
  set_item wifi.header icon="$icon_main" icon.color="$icon_color"
}

set_status_line() {
  local info_airport info_sys ssid hotspot ip pct icon quality color band online text
  info_airport=$(airport_info)
  ssid=$(wifi_current_ssid)
  hotspot=$(wifi_hotspot_name)
  ip=$(wifi_ip_addr)
  if [[ -n "$info_airport" ]]; then
    read -r pct icon quality color < <(wifi_signal_from_airport "$info_airport" | tr '|' ' ')
    band=$(wifi_band_suffix_from_airport "$info_airport")
  else
    info_sys=$(wifi_system_info)
    read -r pct icon quality color < <(wifi_signal_from_sysinfo "$info_sys" | tr '|' ' ')
    band=$(wifi_band_suffix_from_sysinfo "$info_sys")
  fi
  online=1; has_internet && online=0 || online=1

  if [[ -n "$hotspot" ]]; then
    text="Personal Hotspot: $hotspot"
  elif [[ -n "$ssid" ]]; then
    text="Connected to: $ssid$band"
    if (( pct > 0 )); then
      text+=" • Signal ${pct}% (${quality})"
    fi
  elif [[ -n "$ip" ]]; then
    text="Connected (network name unavailable)"
  else
    text="Wi‑Fi: Offline"
  fi
  if (( online != 0 )) && [[ -n "$ssid$ip$hotspot" ]]; then
    text+=" • No Internet"
  fi
  set_item wifi.status label="$text" label.color="$PINK"
}

hide_pref_rows() {
  for i in $(seq 1 10); do set_item wifi.net."$i" drawing=off; done
}

scan_networks_map() {
  # Build lines: x|SSID|RSSI using airport -s; keep strongest per SSID
  local ap line ssid rssi best tmpfile
  ap=$(airport_bin)
  [[ ! -x "$ap" ]] && return
  tmpfile="/tmp/sketchybar_wifi_scan.$USER"
  : > "$tmpfile" || true
  "$ap" -s 2>/dev/null | tail -n +2 | while IFS= read -r line; do
    # SSID can contain spaces; airport aligns columns. Take first 32 chars as SSID field and trim
    ssid=$(echo "$line" | awk '{print substr($0,1,32)}' | sed 's/[[:space:]]*$//')
    rssi=$(echo "$line" | awk '{print $(NF-5)}')
    [[ -z "$ssid" || -z "$rssi" ]] && continue
    if grep -Fq "|$ssid|" "$tmpfile" 2>/dev/null; then
      best=$(awk -F'|' -v s="$ssid" '$2==s{print $3}' "$tmpfile" 2>/dev/null)
      if (( rssi > best )); then
        sed -i '' -e "/|$ssid|/d" "$tmpfile" 2>/dev/null || true
        printf "x|%s|%s\n" "$ssid" "$rssi" >> "$tmpfile"
      fi
    else
      printf "x|%s|%s\n" "$ssid" "$rssi" >> "$tmpfile"
    fi
  done
  cat "$tmpfile" 2>/dev/null || true
}

wifi_icon_for_pct() {
  local pct="$1"
  if (( pct >= 70 )); then echo "$WIFI_SIGNAL_3"; return; fi
  if (( pct >= 40 )); then echo "$WIFI_SIGNAL_2"; return; fi
  if (( pct >= 10 )); then echo "$WIFI_SIGNAL_1"; return; fi
  echo "$WIFI_OFF"
}

fill_preferred_rows() {
  : > "$PREF_MAP_FILE" || true
  local ssid cur i=1 color state rssi pct icon scan
  cur=$(wifi_current_ssid)
  scan=$(scan_networks_map || true)
  while IFS= read -r ssid; do
    [[ -z "$ssid" ]] && continue
    rssi=$(echo "$scan" | awk -F'|' -v s="$ssid" '$2==s{print $3; exit}')
    if [[ -n "$rssi" ]]; then
      pct=$(awk -v r="$rssi" 'BEGIN{p=((r+100)/70)*100; if(p<0)p=0; if(p>100)p=100; printf("%d", p+0.5)}')
      icon=$(wifi_icon_for_pct "$pct")
      color="$WHITE"
    else
      pct=0; icon="$WIFI_OFF"; color="$PRIMARY_GREY"
    fi
    state=""; [[ "$ssid" == "$cur" ]] && state="Connected"
    set_item wifi.net.$i \
      drawing=on \
      icon="$icon" \
      icon.color="$color" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="${ssid}${state:+  ($state)}" \
      label.color="$color" \
      label.padding_left="$PADDINGS_MEDIUM"
    echo "$i|$ssid" >> "$PREF_MAP_FILE"
    i=$((i+1)); [[ $i -gt 10 ]] && break
  done < <(preferred_networks)
  while (( i <= 10 )); do set_item wifi.net.$i drawing=off; i=$((i+1)); done
  # Ensure header visibility aligns with content
  if [[ -s "$PREF_MAP_FILE" ]]; then
    set_item wifi.prefhdr drawing=on
  else
    set_item wifi.prefhdr drawing=off
  fi
}

refresh_all() {
  local info_airport info_sys ssid hotspot ip pct icon quality color band online icon_main icon_color text
  info_airport=$(airport_info)
  ssid=$(wifi_current_ssid)
  hotspot=$(wifi_hotspot_name)
  ip=$(wifi_ip_addr)
  if [[ -n "$info_airport" ]]; then
    read -r pct icon quality color < <(wifi_signal_from_airport "$info_airport" | tr '|' ' ')
    band=$(wifi_band_suffix_from_airport "$info_airport")
  else
    info_sys=$(wifi_system_info)
    read -r pct icon quality color < <(wifi_signal_from_sysinfo "$info_sys" | tr '|' ' ')
    band=$(wifi_band_suffix_from_sysinfo "$info_sys")
  fi
  online=0
  if [[ -n "$ssid$hotspot$ip" ]]; then
    has_internet || online=1
  fi

  if [[ -n "$hotspot" ]]; then
    icon_main="$WIFI_HOTSPOT"; icon_color="$CYAN"; text="Personal Hotspot: $hotspot"
  elif [[ -n "$ssid" ]]; then
    if (( pct > 0 )); then icon_main="$icon"; icon_color="$color"; else icon_main="$WIFI_SIGNAL_3"; icon_color="$GREEN"; fi
    text="Connected to: $ssid$band"; (( pct > 0 )) && text+=" • Signal ${pct}% (${quality})"
  elif [[ -n "$ip" ]]; then
    icon_main="$WIFI_SIGNAL_3"; icon_color="$PINK"; text="Connected (network name unavailable)"
  else
    icon_main="$WIFI_OFF"; icon_color="$RED"; text="Wi‑Fi: Offline"
  fi
  if (( online != 0 )) && [[ "$icon_main" != "$WIFI_OFF" ]]; then
    icon_main="$WIFI_ERROR"; icon_color="$GREY"; text+=" • No Internet"
  fi

  sketchybar \
    --set wifi icon="$icon_main" icon.color="$icon_color" \
    --set wifi.header icon="$icon_main" icon.color="$icon_color" \
    --set wifi.status label="$text" label.color="$PINK"
}

# --- Entrypoints ------------------------------------------------------------
case "${1:-}" in
  power_toggle)
    wifi_power_toggle
    sleep 1
    refresh_all
    exit 0
    ;;
  populate)
    fill_preferred_rows
    exit 0
    ;;
esac

# --- Event Handling ---------------------------------------------------------
case "$NAME" in
  wifi)
    case "${SENDER:-}" in
      mouse.entered) hover_on "$NAME" ;;
      mouse.exited)  hover_off "$NAME" ;;
      *) refresh_all ;;
    esac
    ;;
  wifi.net.*)
    case "${SENDER:-}" in
      mouse.clicked)
        slot=$(echo "$NAME" | awk -F'.' '{print $3}')
        ssid=$(awk -F'|' -v s="$slot" '$1==s{print $2}' "$PREF_MAP_FILE" 2>/dev/null || true)
        if [[ -n "$ssid" ]]; then
          connect_network "$ssid"
          sleep 2
          refresh_all
          fill_preferred_rows
        fi
        ;;
      mouse.entered) hover_on "$NAME" ;;
      mouse.exited)  hover_off "$NAME" ;;
    esac
    ;;
  wifi.settings)
    case "${SENDER:-}" in
      mouse.entered) hover_on "$NAME" ;;
      mouse.exited)  hover_off "$NAME" ;;
    esac
    ;;
  wifi.header|wifi.status)
    # no-op; refreshed by parent
    ;;
  *)
    refresh_all
    ;;
esac
