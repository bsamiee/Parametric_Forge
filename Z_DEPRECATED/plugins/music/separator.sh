#!/bin/bash
# Title         : separator.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/music/separator.sh
# ----------------------------------------------------------------------------
# Dynamic center separator visibility based on music and system monitor states

# --- Configuration ----------------------------------------------------------
export PATH=/opt/homebrew/bin/:$PATH

# --- State Detection --------------------------------------------------------
GRAPHSTATE="$(sketchybar --query graph | sed 's/\\\\n//g; s/\\\\\\$//g; s/\\\\ //g' | jq -r '.geometry.drawing')"
MUSICSTATE="$(sketchybar --query music | sed 's/\\\\n//g; s/\\\\\\$//g; s/\\\\ //g' | jq -r '.geometry.drawing')"

activitycount=0

if [ "$GRAPHSTATE" = "on" ]; then ((activitycount++)); fi
if [ "$MUSICSTATE" = "on" ]; then ((activitycount++)); fi

# --- Separator Control ------------------------------------------------------

if [ $activitycount -gt 0 ]; then
  sketchybar --set separator_center drawing=on
else
  sketchybar --set separator_center drawing=off
fi
