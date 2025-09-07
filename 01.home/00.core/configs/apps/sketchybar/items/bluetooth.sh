#!/bin/bash
# Title         : bluetooth.sh
# Author        : Parametric Forge
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/bluetooth.sh
# ----------------------------------------------------------------------------
# Bluetooth item with popup: power/discoverable toggles and device list
# Follows the same structure as volume/battery items (popups + plugin)
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

# --- Main Bluetooth Item ----------------------------------------------------
# Subscribe to distributed notifications to avoid polling
sketchybar \
  --add event bt_status "com.apple.bluetooth.status" \
  --add event bt_on "IOBluetoothHostControllerPoweredOnNotification" \
  --add event bt_off "IOBluetoothHostControllerPoweredOffNotification" \
  --add item bluetooth right \
  --set bluetooth \
      script="$PLUGIN_DIR/bluetooth.sh" \
      update_freq=30 \
      click_script="if [ \"\$BUTTON\" = left ]; then sketchybar --set \$NAME popup.drawing=toggle; \"$PLUGIN_DIR/bluetooth.sh\" scan; else \"$PLUGIN_DIR/bluetooth.sh\" power_toggle; fi" \
      updates=on \
      icon="$BLUETOOTH_OFF" \
      icon.font="$TEXT_FONT:$BOLD_WEIGHT:18.0" \
      icon.color="$WHITE" \
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
  --subscribe bluetooth bt_status bt_on bt_off system_woke mouse.entered mouse.exited

# --- Popup: Header ----------------------------------------------------------
sketchybar \
  --add item bluetooth.header popup.bluetooth \
  --set bluetooth.header \
      icon="$BLUETOOTH_ON" \
      icon.font="$TEXT_FONT:$BOLD_WEIGHT:18.0" \
      icon.color="$PRIMARY_GREY" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="Bluetooth" \
      label.font="$TEXT_FONT:$BOLD_WEIGHT:$SIZE_LARGE" \
      label.color="$WHITE" \
      background.drawing=off

# --- Popup: Status Line -----------------------------------------------------
sketchybar \
  --add item bluetooth.status popup.bluetooth \
  --set bluetooth.status \
      icon="" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
      label.color="$PINK" \
      label.padding_left="$PADDINGS_MEDIUM" \
      background.drawing=off \
  --move bluetooth.status after bluetooth.header

# (Removed power toggle row; right-click on main item toggles power)

# --- Popup: Discoverable Toggle --------------------------------------------
sketchybar \
  --add item bluetooth.discoverable popup.bluetooth \
  --set bluetooth.discoverable \
      icon="$BLUETOOTH_SEARCHING" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="Discoverable" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      background.drawing=off \
      script="$PLUGIN_DIR/bluetooth.sh" \
  --subscribe bluetooth.discoverable mouse.clicked mouse.entered mouse.exited

# --- Popup: My Devices header ----------------------------------------------
sketchybar \
  --add item bluetooth.myhdr popup.bluetooth \
  --set bluetooth.myhdr \
      icon="$SEPARATOR_DOT" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_SMALL" \
      icon.color="$LIGHT_WHITE" \
      label="My Devices" \
      label.font="$TEXT_FONT:$BOLD_WEIGHT:$SIZE_SMALL" \
      label.color="$LIGHT_WHITE" \
      background.drawing=off \
  --move bluetooth.myhdr after bluetooth.discoverable

# --- Popup: Device Slots (up to 8) -----------------------------------------
idx=1
while [ "$idx" -le 8 ]; do
  sketchybar \
    --add item bluetooth.dev.$idx popup.bluetooth \
    --set bluetooth.dev.$idx \
        icon.drawing=on \
        icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
        icon.padding_left="$PADDINGS_MEDIUM" \
        label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
        label.color="$WHITE" \
        background.drawing=off \
        drawing=off \
        script="$PLUGIN_DIR/bluetooth.sh" \
    --subscribe bluetooth.dev.$idx mouse.clicked mouse.entered mouse.exited
  idx=$((idx+1))
done

# --- Popup: Nearby Devices header + Scan row -------------------------------
sketchybar \
  --add item bluetooth.nearhdr popup.bluetooth \
  --set bluetooth.nearhdr \
      icon="$SEPARATOR_DOT" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_SMALL" \
      icon.color="$LIGHT_WHITE" \
      label="Nearby Devices" \
      label.font="$TEXT_FONT:$BOLD_WEIGHT:$SIZE_SMALL" \
      label.color="$LIGHT_WHITE" \
      background.drawing=off

# Row reserved for spinner during scanning (hidden when idle)
sketchybar \
  --add item bluetooth.scan popup.bluetooth \
  --set bluetooth.scan \
      drawing=off \
      icon="$BLUETOOTH_SEARCHING" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      background.drawing=off \
      script="$PLUGIN_DIR/bluetooth.sh"

# --- Popup: Nearby Device Slots (up to 8) ----------------------------------
idx=1
while [ "$idx" -le 8 ]; do
  sketchybar \
    --add item bluetooth.near.$idx popup.bluetooth \
    --set bluetooth.near.$idx \
        icon.drawing=on \
        icon.font="$TEXT_FONT:$BOLD_WEIGHT:$SIZE_MEDIUM" \
        icon.padding_left="$PADDINGS_MEDIUM" \
        label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
        label.color="$WHITE" \
        background.drawing=off \
        drawing=off \
        script="$PLUGIN_DIR/bluetooth.sh" \
    --subscribe bluetooth.near.$idx mouse.clicked mouse.entered mouse.exited
  idx=$((idx+1))
done

# --- Popup: Bluetooth Settings ---------------------------------------------
sketchybar \
  --add item bluetooth.settings popup.bluetooth \
  --set bluetooth.settings \
      icon="$PREFERENCES" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="Bluetooth Settings" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      background.drawing=off \
      click_script='open "x-apple.systempreferences:com.apple.preferences.Bluetooth"' \
  --subscribe bluetooth.settings mouse.entered mouse.exited

# --- Popup: Accessory Battery Section --------------------------------------
sketchybar \
  --add item bluetooth.batteryhdr popup.bluetooth \
  --set bluetooth.batteryhdr \
      icon="$SEPARATOR_DOT" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_SMALL" \
      icon.color="$LIGHT_WHITE" \
      label="Accessory Battery" \
      label.font="$TEXT_FONT:$BOLD_WEIGHT:$SIZE_SMALL" \
      label.color="$LIGHT_WHITE" \
      background.drawing=off

for idx in 1 2 3; do
  sketchybar \
    --add item bluetooth.bat.$idx popup.bluetooth \
    --set bluetooth.bat.$idx \
        drawing=off \
        icon.drawing=on \
        icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
        icon.padding_left="$PADDINGS_MEDIUM" \
        label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
        label.color="$WHITE" \
        background.drawing=off \
        script="$PLUGIN_DIR/bluetooth.sh"
done
