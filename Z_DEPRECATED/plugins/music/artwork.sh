#!/bin/bash
# Title         : artwork.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/music/artwork.sh
# ----------------------------------------------------------------------------
# Music artwork display with dynamic media stream detection and caching
# shellcheck disable=SC1091,SC2086

# --- Configuration ----------------------------------------------------------
export PATH=/opt/homebrew/bin/:$PATH
RELPATH=$(dirname "$0")/../..
export RELPATH
source "$HOME/.config/sketchybar/icons.sh"

# --- Process Management -----------------------------------------------------
#SKETCHYBAR_MEDIASTREAM# (important do not remove)
pids=$(ps -p "$(pgrep sh)" | grep '#SKETCHYBAR_MEDIASTREAM#' | awk '{print $1}')

if [[ -n "$pids" ]]; then
  pids+=" $(cat "${TMPDIR}"/sketchybar/pids)"
  echo killing "#SKETCHYBAR_MEDIASTREAM# pids:" "$pids"
  kill -9 $pids
fi

# --- Parameter Setup --------------------------------------------------------
ARTWORK_MARGIN="$1"
BAR_HEIGHT="$2"

# --- Media Stream Handler ---------------------------------------------------

media-control stream | grep --line-buffered 'data' | while IFS= read -r line; do
  if ps -p $$ >/dev/null; then
    pgrep -P $$ >"${TMPDIR}"/sketchybar/pids
  fi

  if ! {
    [[ "$(echo "$line" | jq -r .payload)" == '{}' ]] ||
      { [[ -n "$lastAppPID" ]] && ! ps -p "$lastAppPID" >/dev/null; }
  }; then

    # --- Extract Media Data -------------------------------------------------
    artworkData=$(echo "$line" | jq -r .payload.artworkData)
    currentPID=$(echo "$line" | jq -r .payload.processIdentifier)
    playing=$(echo "$line" | jq -r .payload.playing)

    # --- Artwork Processing -------------------------------------------------

    if [[ $artworkData != "null" ]]; then
      tmpfile=$(mktemp "${TMPDIR}"sketchybar/cover.XXXXXXXXXX)
      echo "$artworkData" | base64 -d >"$tmpfile"

      case $(identify -ping -format '%m' "$tmpfile") in
      "JPEG")
        ext=jpg
        mv "$tmpfile" "$tmpfile.$ext"
        ;;
      "PNG")
        ext=png
        mv "$tmpfile" "$tmpfile.$ext"
        ;;
      "TIFF")
        mv "$tmpfile" "$tmpfile.tiff"
        magick "$tmpfile.tiff" "$tmpfile.jpg"
        ext=jpg
        ;;
      esac

      scale=$(bc <<<"scale=4;
        ( ($BAR_HEIGHT - $ARTWORK_MARGIN * 2) / $(identify -ping -format '%h' "$tmpfile.$ext") )
      ")
      icon_width=$(bc <<<"scale=0;
        ( $(identify -ping -format '%w' "$tmpfile.$ext") * $scale )
      ")

      sketchybar --set "$NAME" background.image="$tmpfile.$ext" \
        background.image.scale="$scale" \
        icon.width="$(printf "%.0f" "$icon_width")"

      rm -f "$tmpfile"*
    fi

    # --- Title & Artist Processing ------------------------------------------

    if [[ $(echo "$line" | jq -r .payload.title) != "null" ]]; then
      title_label="$(echo "$line" | jq -r .payload.title)"
      artist=$(echo "$line" | jq -r .payload.artist)
      album=$(echo "$line" | jq -r .payload.album)

      subtitle_label="$artist"
      if [[ -n "$album" ]]; then
        subtitle_label+=" • $album"
      fi

      sketchybar --set "$NAME.title" label="$title_label" \
        --set "$NAME.subtitle" label="$subtitle_label"
    fi

    # --- Play State Indicator -----------------------------------------------

    if [[ $playing != "null" && $(echo "$line" | jq -r .diff) == "true" ]]; then
      case $playing in
      "true")
        sketchybar --set "$NAME" icon.padding_left=-3 \
          --animate tanh 5 \
          --set "$NAME" icon="$MEDIA_PLAY" \
          icon.drawing=on
        {
          sleep 5
          sketchybar --animate tanh 45 --set "$NAME" icon.drawing=false
        } &
        ;;
      "false")
        sketchybar --set "$NAME" icon.padding_left=0 \
          --animate tanh 5 \
          --set "$NAME" icon="$MEDIA_PAUSE" \
          icon.drawing=on
        {
          sleep 5
          sketchybar --animate tanh 45 --set "$NAME" icon.drawing=false
        } &
        ;;
      esac
    fi

    if [[ $currentPID != "null" ]]; then
      lastAppPID=$currentPID
    fi

    sketchybar --set "$NAME" drawing=on \
      --set "$NAME.title" drawing=on \
      --set "$NAME.subtitle" drawing=on \
      --trigger activities_update

  else
    # --- Hide Music Player --------------------------------------------------

    sketchybar --set "$NAME" drawing=off \
      --set "$NAME.title" drawing=off \
      --set "$NAME.subtitle" drawing=off \
      --trigger activities_update

    lastAppPID=""
  fi

done
