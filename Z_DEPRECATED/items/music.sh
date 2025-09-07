#!/bin/bash
# Title         : music.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/items/music.sh
# ----------------------------------------------------------------------------
# Music player items with artwork, title, and controls
# shellcheck disable=SC1091

# --- Configuration ----------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"

# --- Parameters -------------------------------------------------------------
ARTWORK_MARGIN=5
TITLE_MARGIN=11
INFO_WIDTH=80

command -v 'menubar' 2>/dev/null 1>&2 || alias menubar="$HOME/.config/sketchybar/menubar"

# --- Script Paths -----------------------------------------------------------
SCRIPT_MUSIC="export PATH=$PATH; $HOME/.config/sketchybar/plugins/music/artwork.sh $ARTWORK_MARGIN $HEIGHT_BAR #SKETCHYBAR_MEDIASTREAM#"
SCRIPT_CLICK_MUSIC_ARTWORK="export PATH=$PATH; media-control toggle-play-pause"
SCRIPT_MUSIC_TITLE="export PATH=$PATH; $HOME/.config/sketchybar/plugins/music/title.sh"
SCRIPT_CLICK_MUSIC_TITLE="export PATH=$PATH; menubar -s \"Control Center,NowPlaying\""
SCRIPT_CENTER_SEP="export PATH=$PATH; $HOME/.config/sketchybar/plugins/music/separator.sh"

# --- Artwork Configuration --------------------------------------------------
music_artwork=(
  drawing=off
  script="$SCRIPT_MUSIC"
  click_script="$SCRIPT_CLICK_MUSIC_ARTWORK"
  icon="$MEDIA_PLAY"
  icon.drawing=off
  icon.color="$PINK"
  icon.shadow.drawing=on
  icon.shadow.color="$PRIMARY_BLACK"
  icon.shadow.distance=3
  icon.align=center
  label.drawing=off
  icon.padding_right=0
  icon.padding_left=-3
  background.drawing=on
  background.height=$(($HEIGHT_BAR - $ARTWORK_MARGIN * 2))
  background.image.border_color="$GREY"
  background.image.border_width=1
  background.image.corner_radius=4
  background.image.padding_right=1
  update_freq=0
  padding_left=0
  padding_right=8
)

# --- Title Configuration ----------------------------------------------------
music_title=(
  label=Title
  drawing=off
  script="$SCRIPT_MUSIC_TITLE"
  click_script="$SCRIPT_CLICK_MUSIC_TITLE"
  label.color="$WHITE"
  icon.drawing=off
  label.align=right
  label.width=$INFO_WIDTH
  label.max_chars=13
  label.font="$TEXT_FONT:Semibold:10.0"
  scroll_texts=off
  padding_left=-$INFO_WIDTH
  padding_right=0
  y_offset=$(($HEIGHT_BAR / 2 - $TITLE_MARGIN))
)

# --- Subtitle Configuration -------------------------------------------------
music_subtitle=(
  label=SubTitle
  drawing=off
  script="$SCRIPT_MUSIC_TITLE"
  click_script="$SCRIPT_CLICK_MUSIC_TITLE"
  label.color="$FAINT_WHITE"
  icon.drawing=off
  label.align=right
  label.width=$INFO_WIDTH
  label.max_chars=14
  label.font="$TEXT_FONT:Semibold:9.0"
  scroll_texts=off
  padding_left=0
  padding_right=0
  y_offset=$((-($HEIGHT_BAR / 2) + $TITLE_MARGIN))
)

# --- Separator Configuration ------------------------------------------------
center_separator=(
  icon="$SEPARATOR_LINE"
  script="$SCRIPT_CENTER_SEP"
  icon.color="$GREY"
  icon.font="$TEXT_FONT:Bold:16.0"
  icon.y_offset=2
  label.drawing=off
  icon.padding_left=0
  icon.padding_right=0
  update_freq=0
  updates=on
)

# --- Item Creation ----------------------------------------------------------
sketchybar --add item separator_center center \
  --set separator_center "${center_separator[@]}" \
  --add event activities_update \
  sketchybar --subscribe separator_center activities_update

sketchybar --add item music q \
  --set music "${music_artwork[@]}" \
  --add item music.title q \
  --set music.title "${music_title[@]}" \
  --add item music.subtitle q \
  --set music.subtitle "${music_subtitle[@]}" \
  --subscribe music.title mouse.entered mouse.exited \
  --subscribe music.subtitle mouse.entered mouse.exited
