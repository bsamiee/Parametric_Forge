#!/bin/bash
# Title         : system-monitor.sh
# Author        : Parametric Forge
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/system-monitor.sh
# ----------------------------------------------------------------------------
# Activity Monitor-style widget with compact graph + popup details
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

# --- Main System Monitor Graph ---------------------------------------------
# Left click: toggle popup
sketchybar \
  --add graph system_monitor right \
  --set system_monitor \
      script="$PLUGIN_DIR/system-monitor.sh" \
      click_script="if [ \"\$BUTTON\" = left ]; then sketchybar --set \$NAME popup.drawing=toggle; elif [ \"\$BUTTON\" = right ]; then open -a 'Activity Monitor'; fi" \
      update_freq=3 \
      updates=on \
      icon="$ACTIVITY" \
      icon.font="$SYMBOL_FONT:$MEDIUM_WEIGHT:$SIZE_MEDIUM" \
      icon.color="$PRIMARY_CYAN" \
      icon.padding_left="$PADDINGS_MEDIUM" \
      icon.padding_right="$PADDINGS_SMALL" \
      graph.color="$GREY" \
      graph.fill_color="$GREY" \
      graph.line_width=2 \
      label.drawing=off \
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
  --subscribe system_monitor mouse.entered mouse.exited mouse.clicked system_woke

# Compact percent to the right of the graph
sketchybar \
  --add item system_monitor.percent right \
  --set system_monitor.percent \
      label="0%" \
      label.font="$TEXT_FONT:$MEDIUM_WEIGHT:$SIZE_SMALL" \
      label.color="$WHITE" \
      label.padding_left="$PADDINGS_NONE" \
      label.padding_right="$PADDINGS_MEDIUM" \
      icon.drawing=off \
      background.drawing=off \
      script="$PLUGIN_DIR/system-monitor.sh" \
  --subscribe system_monitor.percent mouse.entered mouse.exited

# Small status label (top process/power)
sketchybar \
  --add item system_monitor.label right \
  --set system_monitor.label \
      label="Loading..." \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_XSMALL" \
      label.color="$LIGHT_GREY" \
      label.max_chars=25 \
      label.padding_left="$PADDINGS_NONE" \
      label.padding_right="$PADDINGS_MEDIUM" \
      icon.drawing=off \
      background.drawing=off \
      script="$PLUGIN_DIR/system-monitor.sh" \
  --subscribe system_monitor.label mouse.entered mouse.exited

# --- Popup: Detailed Metrics ------------------------------------------------
sketchybar \
  --add item system_monitor.cpu popup.system_monitor \
  --set system_monitor.cpu \
      label="CPU    [----------]   0%" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
      label.color="$WHITE" \
      label.padding_left="$PADDINGS_MEDIUM" \
      label.padding_right="$PADDINGS_MEDIUM" \
      icon.drawing=off \
      background.drawing=off \
  \
  --add item system_monitor.memory popup.system_monitor \
  --set system_monitor.memory \
      label="Memory [----------]   0%" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
      label.color="$WHITE" \
      label.padding_left="$PADDINGS_MEDIUM" \
      label.padding_right="$PADDINGS_MEDIUM" \
      icon.drawing=off \
      background.drawing=off \
  \
  --add item system_monitor.disk popup.system_monitor \
  --set system_monitor.disk \
      label="Disk   [----------]   0%" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
      label.color="$WHITE" \
      label.padding_left="$PADDINGS_MEDIUM" \
      label.padding_right="$PADDINGS_MEDIUM" \
      icon.drawing=off \
      background.drawing=off \
  \
  --add item system_monitor.network popup.system_monitor \
  --set system_monitor.network \
      label="Network[----------]   0%" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
      label.color="$WHITE" \
      label.padding_left="$PADDINGS_MEDIUM" \
      label.padding_right="$PADDINGS_MEDIUM" \
      icon.drawing=off \
      background.drawing=off \
  \
  --add item system_monitor.power popup.system_monitor \
  --set system_monitor.power \
      label="Power  [----------]   0W" \
      label.font="$TEXT_FONT:$REGULAR_WEIGHT:$SIZE_SMALL" \
      label.color="$WHITE" \
      label.padding_left="$PADDINGS_MEDIUM" \
      label.padding_right="$PADDINGS_MEDIUM" \
      icon.drawing=off \
      background.drawing=off \
\
  --add bracket system_monitor_group system_monitor system_monitor.percent system_monitor.label \
  --set system_monitor_group \
      drawing=on \
      background.drawing=on \
      background.height="$HEIGHT_ITEM" \
      background.corner_radius="$RADIUS_MEDIUM" \
      background.border_width="$BORDER_NONE" \
      background.color="$TRANSPARENT"

