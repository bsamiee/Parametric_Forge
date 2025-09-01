#!/bin/bash
# Title         : space.sh
# Author        : Bardia Samiee (adapted from FelixKratz)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/space.sh
# ----------------------------------------------------------------------------
# Individual space interaction and animation handling

# --- Space Animation Handler ------------------------------------------------
update() {
  WIDTH="dynamic"
  if [ "$SELECTED" = "true" ]; then
    WIDTH="0"
  fi

  sketchybar --animate tanh 20 --set "$NAME" icon.highlight="$SELECTED" label.width="$WIDTH"
}

# --- Mouse Event Handler ----------------------------------------------------
mouse_clicked() {
  if [ "$BUTTON" = "right" ]; then
    yabai -m space --destroy "$SID"
    sketchybar --trigger space_change --trigger windows_on_spaces
  else
    yabai -m space --focus "$SID" 2>/dev/null
  fi
}

# --- Event Dispatcher -------------------------------------------------------
case "$SENDER" in
"mouse.clicked")
  mouse_clicked
  ;;
*)
  update
  ;;
esac
