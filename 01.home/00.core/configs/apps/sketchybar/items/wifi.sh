#!/bin/bash
# Title         : wifi.sh
# Author        : Parametric Forge
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/wifi.sh
# ----------------------------------------------------------------------------
# Wi‑Fi item with popup: status + preferred networks + settings
# Mirrors the structure and quality of bluetooth/volume items.
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

# --- Main Wi‑Fi Item --------------------------------------------------------
# Left click populates + toggles popup, Right click toggles Wi‑Fi power
sketchybar \
  --add item wifi right \
  --set wifi \
      script="$PLUGIN_DIR/wifi.sh" \
      click_script="if [ \"\$BUTTON\" = left ]; then \"$PLUGIN_DIR/wifi.sh\" populate; sketchybar --set \$NAME popup.drawing=toggle; elif [ \"\$BUTTON\" = right ]; then \"$PLUGIN_DIR/wifi.sh\" power_toggle; fi" \
      updates=on \
      update_freq=20 \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
      icon.color="$GREY" \
      icon.padding_left="$PADDINGS_SMALL" \
      icon.padding_right="$PADDINGS_SMALL" \
      label.drawing=off \
      label.width=0 \
      label.padding_left="$PADDINGS_NONE" \
      label.padding_right="$PADDINGS_NONE" \
      background.color="$TRANSPARENT" \
      background.corner_radius="$RADIUS_MEDIUM" \
      background.height="$HEIGHT_ITEM" \
      popup.align=center \
      popup.y_offset=0 \
      popup.height="$HEIGHT_ITEM" \
      popup.blur_radius="$BLUR_RADIUS_STANDARD" \
      popup.background.color="$PRIMARY_BLACK" \
      popup.background.corner_radius="$RADIUS_LARGE" \
      popup.background.border_color="$PRIMARY_WHITE" \
      popup.background.border_width="$BORDER_THIN" \
      popup.background.shadow.drawing=on \
      popup.background.shadow.color="$SHADOW_HEAVY" \
      popup.background.shadow.angle="$SHADOW_ANGLE" \
      popup.background.shadow.distance="$SHADOW_DISTANCE" \
  --subscribe wifi system_woke mouse.entered mouse.exited

# --- Popup: Header ----------------------------------------------------------
sketchybar \
  --add item wifi.header popup.wifi \
  --set wifi.header \
      icon="$WIFI_ERROR" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_LARGE" \
      icon.color="$GREY" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="Wi‑Fi" \
      label.font="$TEXT_FONT:$BOLD_WEIGHT:$SIZE_LARGE" \
      label.color="$WHITE" \
      background.drawing=off

# --- Popup: Status Line -----------------------------------------------------
sketchybar \
  --add item wifi.status popup.wifi \
  --set wifi.status \
      icon="" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
      label.color="$PINK" \
      label.padding_left="$PADDINGS_MEDIUM" \
      background.drawing=off \
  --move wifi.status after wifi.header

# --- Popup: Preferred Networks header --------------------------------------
sketchybar \
  --add item wifi.prefhdr popup.wifi \
  --set wifi.prefhdr \
      icon.drawing=off \
      label="Preferred Networks" \
      label.font="$TEXT_FONT:$BOLD_WEIGHT:$SIZE_SMALL" \
      label.color="$LIGHT_WHITE" \
      background.drawing=off \
      drawing=off

# --- Popup: Preferred Network Slots (up to 10) ------------------------------
idx=1
while [ "$idx" -le 10 ]; do
  sketchybar \
    --add item wifi.net.$idx popup.wifi \
    --set wifi.net.$idx \
        icon.drawing=on \
        icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
        icon.padding_left="$PADDINGS_MEDIUM" \
        label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
        label.color="$WHITE" \
        background.drawing=off \
        drawing=off \
        script="$PLUGIN_DIR/wifi.sh" \
    --subscribe wifi.net.$idx mouse.clicked mouse.entered mouse.exited
  idx=$((idx+1))
done

# --- Popup: Wi‑Fi Settings --------------------------------------------------
sketchybar \
  --add item wifi.settings popup.wifi \
  --set wifi.settings \
      icon="$PREFERENCES" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="Wi‑Fi Settings" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      background.drawing=off \
      click_script='menubar -s "Control Center,WiFi" 2>/dev/null || open "x-apple.systempreferences:com.apple.preference.network"' \
  --subscribe wifi.settings mouse.entered mouse.exited

# --- Popup Ordering ---------------------------------------------------------
sketchybar \
  --reorder \
    wifi.header \
    wifi.status \
    wifi.prefhdr \
    wifi.net.1 wifi.net.2 wifi.net.3 wifi.net.4 wifi.net.5 \
    wifi.net.6 wifi.net.7 wifi.net.8 wifi.net.9 wifi.net.10 \
    wifi.settings
