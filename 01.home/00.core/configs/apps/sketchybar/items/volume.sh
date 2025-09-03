#!/bin/bash
# Title         : volume.sh
# Author        : Bardia Samiee (adapted from reference)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/volume.sh
# ----------------------------------------------------------------------------
# Volume control with interactive slider and dynamic icon
# shellcheck disable=SC1091

# --- Load Configuration Variables -------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"

# --- Volume Slider Configuration -------------------------------------------
volume_slider_config=(
  script="$HOME/.config/sketchybar/plugins/volume.sh"
  updates=on

  padding_left="$PADDINGS_NONE"
  padding_right="$PADDINGS_NONE"

  label.drawing=off
  icon.drawing=off

  slider.highlight_color="$PRIMARY_GREEN"
  slider.background.height=5
  slider.background.corner_radius=3
  slider.background.color="$LIGHT_DARK_GREY"
  slider.knob="􀀁"
  slider.knob.drawing=off
  slider.width=0
)

# --- Volume Icon Configuration ----------------------------------------------
volume_icon_config=(
  click_script="$HOME/.config/sketchybar/plugins/volume.sh"

  icon.align=left
  icon.font="$SYMBOL_FONT:$REGULAR_WEIGHT:$SIZE_LARGE"
  icon.color="$PRIMARY_PURPLE"
  icon.padding_left="$PADDINGS_LARGE"
  icon.padding_right="$PADDINGS"

  label.drawing=off
  label.width=32
  label.padding_left="$PADDINGS_NONE"
  label.padding_right="$PADDINGS_NONE"
  label.align=left
  label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_LARGE"
  label.color="$WHITE"

  padding_left="$PADDINGS_NONE"
  padding_right="$PADDINGS_NONE"

  background.drawing=off
)

# --- Create Volume Items ----------------------------------------------------
sketchybar --add slider volume right \
  --set volume "${volume_slider_config[@]}" \
  --subscribe volume volume_change mouse.clicked mouse.entered mouse.exited \
  \
  --add item volume_icon right \
  --set volume_icon "${volume_icon_config[@]}" \
  --subscribe volume_icon mouse.clicked mouse.entered mouse.exited
