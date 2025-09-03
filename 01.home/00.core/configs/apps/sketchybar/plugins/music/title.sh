#!/bin/bash
# Title         : title.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/music/title.sh
# ----------------------------------------------------------------------------
# Music title scrolling text control with hover-based auto-scroll functionality

# --- Scroll Function --------------------------------------------------------
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
    sketchybar --set "music.title" scroll_texts="$1"
    sketchybar --set "music.subtitle" scroll_texts="$1"
  fi

}

# --- Event Handler ----------------------------------------------------------

case "$SENDER" in
"mouse.entered")
  setscroll on
  ;;
"mouse.exited")
  setscroll off
  ;;
esac
