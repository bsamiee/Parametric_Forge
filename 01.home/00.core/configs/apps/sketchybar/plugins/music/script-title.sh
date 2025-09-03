#!/bin/bash
# Title         : script-title.sh
# Author        : Bardia Samiee (adapted from reference)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/music/script-title.sh
# ----------------------------------------------------------------------------
# Music title scroll text management
setscroll() {
  STATE="$(sketchybar --query "music.title" | sed 's/\\\\n//g; s/\\\\\\$//g; s/\\\\ //g' | jq -r '.geometry.scroll_texts')"

  case "$1" in
  "on")
    target="off"
    ;;
  "off")
    target="on"
    ;;
  esac

  if [[ "$STATE" == "$target" ]]; then
    sketchybar --set "music.title" scroll_texts=$1
    sketchybar --set "music.subtitle" scroll_texts=$1
  fi

}

### Only scroll text on mouse hover for better performances

case "$SENDER" in
"mouse.entered")
  setscroll on
  ;;
"mouse.exited")
  setscroll off
  ;;
esac