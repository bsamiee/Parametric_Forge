#!/bin/bash
# Title         : volume.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/volume.sh
# ----------------------------------------------------------------------------
# Volume item configuration with popup slider and precise control interface
# shellcheck disable=SC1091
# shellcheck disable=SC2154

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

# --- Main Volume Item Configuration -----------------------------------------
sketchybar \
  --add item volume right \
  --set volume \
      script="$PLUGIN_DIR/volume.sh" \
      click_script="[ \"\$BUTTON\" = left ] && sketchybar --set \$NAME popup.drawing=toggle; [ \"\$BUTTON\" = right ] && \"$PLUGIN_DIR/volume.sh\" mute" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
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
  --subscribe volume volume_change system_woke mouse.scrolled \
  --subscribe volume mouse.entered mouse.exited

# --- Popup: Header ----------------------------------------------------------
sketchybar \
  --add item volume.header popup.volume \
  --set volume.header \
      icon="$VOLUME_100" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_LARGE" \
      icon.color="$PURPLE" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="Volume" \
      label.font="$TEXT_FONT:$BOLD_WEIGHT:$SIZE_LARGE" \
      label.color="$WHITE" \
      background.drawing=off

# --- Popup: Status Line (above slider) --------------------------------------
sketchybar \
  --add item volume.details popup.volume \
  --set volume.details \
      icon="" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
      label.color="$GREY" \
      label.padding_left="$PADDINGS_MEDIUM" \
      background.drawing=off \
  --move volume.details after volume.header

# --- Popup: Slider ----------------------------------------------------------
sketchybar \
  --add slider volume.slider popup.volume \
  --set volume.slider \
      script="$PLUGIN_DIR/volume.sh" \
      slider.width=140 \
      slider.highlight_color="$WHITE" \
      slider.background.height=6 \
      slider.background.corner_radius=3 \
      slider.background.color="$LIGHT_DARK_GREY" \
      slider.knob="$SEPARATOR_DOT" \
      slider.knob.drawing=on \
  --subscribe volume.slider mouse.clicked mouse.scrolled

# --- Popup: Fine Adjustment Buttons -----------------------------------------
# Increase volume
sketchybar \
  --add item volume.inc popup.volume \
  --set volume.inc \
      icon="$ADJUST_PLUS" \
      icon.font="$SYMBOL_FONT:$BOLD_WEIGHT:$SIZE_MEDIUM" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="+2% | +10%" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      background.drawing=off \
      click_script="$PLUGIN_DIR/volume.sh inc" \
  --subscribe volume.inc mouse.entered mouse.exited

# Decrease volume
sketchybar \
  --add item volume.dec popup.volume \
  --set volume.dec \
      icon="$ADJUST_MINUS" \
      icon.font="$SYMBOL_FONT:$BOLD_WEIGHT:$SIZE_MEDIUM" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="-2% | -10%" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      background.drawing=off \
      click_script="$PLUGIN_DIR/volume.sh dec" \
  --subscribe volume.dec mouse.entered mouse.exited

# --- Popup: Open Sound Settings ---------------------------------------------
sketchybar \
  --add item volume.settings popup.volume \
  --set volume.settings \
      icon="$PREFERENCES" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="Sound Settings…" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      background.drawing=off \
      click_script='open "x-apple.systempreferences:com.apple.preference.sound"' \
  --subscribe volume.settings mouse.entered mouse.exited
