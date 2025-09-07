#!/bin/bash
# Title         : mic.sh
# Author        : Parametric Forge
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/mic.sh
# ----------------------------------------------------------------------------
# Microphone item configuration (popup slider, mute toggle, scroll adjust)
# Mirrors the structure and quality of volume/battery items.
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

# --- Main Mic Item ----------------------------------------------------------
# Left click toggles popup, Right click toggles mute
sketchybar \
  --add item mic right \
  --set mic \
      script="$PLUGIN_DIR/mic.sh" \
      click_script="if [ \"\$BUTTON\" = left ]; then sketchybar --set \$NAME popup.drawing=toggle; elif [ \"\$BUTTON\" = right ]; then \"$PLUGIN_DIR/mic.sh\" mute; fi" \
      updates=on \
      update_freq=30 \
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
  --subscribe mic system_woke mouse.scrolled \
  --subscribe mic mouse.entered mouse.exited

# --- Popup: Header ----------------------------------------------------------
sketchybar \
  --add item mic.header popup.mic \
  --set mic.header \
      icon="$MIC_ON" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_LARGE" \
      icon.color="$PINK" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="Microphone" \
      label.font="$TEXT_FONT:$BOLD_WEIGHT:$SIZE_LARGE" \
      label.color="$WHITE" \
      background.drawing=off

# --- Popup: Status Line -----------------------------------------------------
sketchybar \
  --add item mic.details popup.mic \
  --set mic.details \
      icon="" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
      label.color="$GREY" \
      label.padding_left="$PADDINGS_MEDIUM" \
      background.drawing=off \
  --move mic.details after mic.header

# --- Popup: Slider ----------------------------------------------------------
sketchybar \
  --add slider mic.slider popup.mic \
  --set mic.slider \
      script="$PLUGIN_DIR/mic.sh" \
      slider.width=140 \
      slider.highlight_color="$WHITE" \
      slider.background.height=6 \
      slider.background.corner_radius=3 \
      slider.background.color="$LIGHT_DARK_GREY" \
      slider.knob="$SEPARATOR_DOT" \
      slider.knob.drawing=on \
  --subscribe mic.slider mouse.clicked mouse.scrolled

# Optional: Cycle input device (shown only if SwitchAudioSource is available)
sketchybar \
  --add item mic.cycle popup.mic \
  --set mic.cycle \
      drawing=off \
      icon="$MIC_ON" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="Cycle Input Device" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      background.drawing=off \
      click_script="$PLUGIN_DIR/mic.sh cycle" \
  --subscribe mic.cycle mouse.entered mouse.exited

# --- Popup: Fine Adjustment Buttons ----------------------------------------
# Increase mic input volume
sketchybar \
  --add item mic.inc popup.mic \
  --set mic.inc \
      icon="$ADJUST_PLUS" \
      icon.font="$SYMBOL_FONT:$BOLD_WEIGHT:$SIZE_MEDIUM" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="+2% | +10%" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      background.drawing=off \
      click_script="$PLUGIN_DIR/mic.sh inc" \
  --subscribe mic.inc mouse.entered mouse.exited

# Decrease mic input volume
sketchybar \
  --add item mic.dec popup.mic \
  --set mic.dec \
      icon="$ADJUST_MINUS" \
      icon.font="$SYMBOL_FONT:$BOLD_WEIGHT:$SIZE_MEDIUM" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="-2% | -10%" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      background.drawing=off \
      click_script="$PLUGIN_DIR/mic.sh dec" \
  --subscribe mic.dec mouse.entered mouse.exited

# --- Popup: Open Sound Settings --------------------------------------------
sketchybar \
  --add item mic.settings popup.mic \
  --set mic.settings \
      icon="$PREFERENCES" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      label="Sound Settings…" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_MEDIUM" \
      label.color="$WHITE" \
      background.drawing=off \
      click_script='open "x-apple.systempreferences:com.apple.preference.sound"' \
  --subscribe mic.settings mouse.entered mouse.exited

# --- Popup Ordering ---------------------------------------------------------
sketchybar \
  --reorder \
    mic.header \
    mic.details \
    mic.slider \
    mic.inc \
    mic.dec \
    mic.cycle \
    mic.settings
