#!/bin/bash
# Title         : battery.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/battery.sh
# ----------------------------------------------------------------------------
# Battery item configuration with advanced popup interface and charge controls
# shellcheck disable=SC1091
# shellcheck disable=SC2154

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

# --- Battery Presence Check -------------------------------------------------
if [[ -z "${SB_FORCE_BATTERY:-}" ]]; then
  if pmset -g batt 2>/dev/null | grep -qi "no.*battery"; then
    # No battery detected: do not create the item
    exit 0
  fi
fi

# --- Main Battery Item Configuration ----------------------------------------
sketchybar \
  --add item battery right \
  --set battery \
      script="$PLUGIN_DIR/battery.sh" \
      click_script="[ \"\$BUTTON\" = left ] && sketchybar --set \$NAME popup.drawing=toggle" \
      updates=on \
      update_freq=60 \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
      icon.color="$WHITE" \
      icon.padding_left="$PADDINGS_SMALL" \
      icon.padding_right="$PADDINGS_SMALL" \
      label.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
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
  --subscribe battery system_woke system_will_sleep power_source_change mouse.clicked mouse.entered mouse.exited

# --- Popup Header Configuration ---------------------------------------------
sketchybar \
  --add item battery.header popup.battery \
  --set battery.header \
      icon="$BATTERY_CHARGING" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_LARGE" \
      icon.color="$PRIMARY_GREEN" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="Battery" \
      label.font="$TEXT_FONT:$BOLD_WEIGHT:$SIZE_LARGE" \
      label.color="$WHITE" \
      background.drawing=off

# --- Popup Slider Configuration ---------------------------------------------
# Label for the slider
sketchybar \
  --add item battery.limit_label popup.battery \
  --set battery.limit_label \
      icon="" \
      label="Charging Threshold" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
      label.color="$PINK" \
      label.padding_left="$PADDINGS_MEDIUM" \
      background.drawing=off

# Slider itself (0-100)
sketchybar \
  --add slider battery.slider popup.battery \
  --set battery.slider \
      script="$PLUGIN_DIR/battery.sh" \
      updates=on \
      slider.width=140 \
      slider.highlight_color="$WHITE" \
      slider.background.height=6 \
      slider.background.corner_radius=3 \
      slider.background.color="$LIGHT_DARK_GREY" \
      slider.knob="$SEPARATOR_DOT" \
      slider.knob.drawing=on \
  --subscribe battery.slider mouse.clicked mouse.scrolled

# --- Popup Control Buttons Configuration ------------------------------------
# Increase threshold
sketchybar \
  --add item battery.inc popup.battery \
  --set battery.inc \
      icon="$ADJUST_PLUS" \
      icon.font="$SYMBOL_FONT:$BOLD_WEIGHT:$SIZE_MEDIUM" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="+1% | +5%" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      background.drawing=off \
      click_script="$PLUGIN_DIR/battery.sh inc" \
  --subscribe battery.inc mouse.entered mouse.exited

# Decrease threshold
sketchybar \
  --add item battery.dec popup.battery \
  --set battery.dec \
      icon="$ADJUST_MINUS" \
      icon.font="$SYMBOL_FONT:$BOLD_WEIGHT:$SIZE_MEDIUM" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="-1% | -5%" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      background.drawing=off \
      click_script="$PLUGIN_DIR/battery.sh dec" \
  --subscribe battery.dec mouse.entered mouse.exited

# --- Popup Action Buttons Configuration -------------------------------------
# 1) Top Up (AlDente-like)
sketchybar \
  --add item battery.topup popup.battery \
  --set battery.topup \
      icon="$BATTERY_100" \
      label="Top Up" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      background.drawing=off \
      click_script="$PLUGIN_DIR/battery.sh topup" \
  --subscribe battery.topup mouse.entered mouse.exited

# 2) Adapter toggle (optional sailing mode)
sketchybar \
  --add item battery.adapter popup.battery \
  --set battery.adapter \
      icon="$BATTERY_ADAPTER" \
      label="Adapter" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      background.drawing=off \
      click_script="$PLUGIN_DIR/battery.sh adapter" \
  --subscribe battery.adapter mouse.entered mouse.exited

# 3) Discharge to Limit (one-shot)
sketchybar \
  --add item battery.discharge popup.battery \
  --set battery.discharge \
      icon="$BATTERY_DISCHARGE" \
      label="Discharge to Limit" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      background.drawing=off \
      click_script="$PLUGIN_DIR/battery.sh discharge" \
  --subscribe battery.discharge mouse.entered mouse.exited

# --- Popup Status Display Configuration -------------------------------------
sketchybar \
  --add item battery.details popup.battery \
  --set battery.details \
      icon="" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
      label.color="$PINK" \
      label.padding_left="$PADDINGS_MEDIUM" \
      label.y_offset=0 \
      background.drawing=off \
  --move battery.details after battery.slider

# Power source line (clean status about draw source below slider)
sketchybar \
  --add item battery.power popup.battery \
  --set battery.power \
      icon="" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
      label.color="$GREY" \
      label.padding_left="$PADDINGS_MEDIUM" \
      background.drawing=off \
  --move battery.power after battery.details

# Temperature line (separate)
sketchybar \
  --add item battery.temp popup.battery \
  --set battery.temp \
      icon="" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
      label.color="$PINK" \
      label.padding_left="$PADDINGS_MEDIUM" \
      label.y_offset=0 \
      background.drawing=off \
  --move battery.temp after battery.details

# --- Popup Item Ordering ----------------------------------------------------
sketchybar \
  --reorder \
    battery.header \
    battery.limit_label \
    battery.slider \
    battery.details \
    battery.power \
    battery.inc \
    battery.dec \
    battery.topup \
    battery.adapter \
    battery.discharge \
    battery.temp
