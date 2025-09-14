#!/usr/bin/env sh
# Title         : rules-signals.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/yabai/rules-signals.sh
# ----------------------------------------------------------------------------
# Application rules and yabai event signals
# shellcheck disable=SC1091,SC2034

set -eu

# --- Grid definitions -------------------------------------------------------
GRID_FULL="1:1:0:0:1:1"
GRID_LEFT_HALF="1:2:0:0:1:1"
GRID_RIGHT_HALF="1:2:1:0:1:1"
GRID_TOP_HALF="2:1:0:0:1:1"
GRID_BOTTOM_HALF="2:1:0:1:1:1"
GRID_LEFT_THIRD="1:3:0:0:1:1"
GRID_MIDDLE_THIRD="1:3:1:0:1:1"
GRID_RIGHT_THIRD="1:3:2:0:1:1"
GRID_TOP_LEFT_QUARTER="2:2:0:0:1:1"
GRID_TOP_RIGHT_QUARTER="2:2:1:0:1:1"
GRID_BOTTOM_LEFT_QUARTER="2:2:0:1:1:1"
GRID_BOTTOM_RIGHT_QUARTER="2:2:1:1:1:1"
GRID_CENTER="6:6:1:1:4:4"

# --- signals: performance optimizations ------------------------------------
yabai -m signal --remove float_small_noninteractive >/dev/null 2>&1 || true
yabai -m signal --add label=float_small_noninteractive \
  event=window_created action="
  info=\$(yabai -m query --windows --window \$YABAI_WINDOW_ID); \
  is_floating=\$(echo \"\$info\" | jq -r '.\"is-floating\"'); \
  can_resize=\$(echo \"\$info\" | jq -r '.\"can-resize\"'); \
  can_move=\$(echo \"\$info\" | jq -r '.\"can-move\"'); \
  role=\$(echo \"\$info\" | jq -r '.role // \"\"'); \
  subrole=\$(echo \"\$info\" | jq -r '.subrole // \"\"'); \
  w=\$(echo \"\$info\" | jq -r '.frame.w // 0'); \
  h=\$(echo \"\$info\" | jq -r '.frame.h // 0'); \
  [ \"\$is_floating\" = 'true' ] && exit 0
  if [ \"\$can_resize\" = 'false' ] && [ \"\$can_move\" = 'false' ]; then
    yabai -m window \$YABAI_WINDOW_ID --toggle float; exit 0; fi
  case \"\$role:\$subrole\" in
    AXWindow:AXDialog|AXWindow:AXSheet|AXWindow:AXSystemDialog)
      yabai -m window \$YABAI_WINDOW_ID --toggle float; exit 0;;
  esac
  if [ \"\${w:-0}\" -lt 400 ] || [ \"\${h:-0}\" -lt 260 ]; then
    yabai -m window \$YABAI_WINDOW_ID --toggle float; fi
"

# --- spaces: layout normalization -------------------------------------------
SPACE_DATA="$(yabai -m query --spaces)"
SPACE_COUNT=$(echo "$SPACE_DATA" | jq length)
echo "$SPACE_DATA" | jq -r '.[].index' | while IFS= read -r space; do
  yabai -m space "$space" --layout bsp 2>/dev/null || true
done
echo "yabai: normalized layouts on $SPACE_COUNT spaces"

# --- rules: system & finder ------------------------------------------------
yabai -m rule --add app="^System Settings$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^System Preferences$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^System Information$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^Activity Monitor$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^Archive Utility$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^Installer$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^Software Update$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^Migration Assistant$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^Disk Utility$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^Console$" manage=off sub-layer=below || true

yabai -m rule --add app="^Finder$" role="^AXWindow$" subrole="^AXStandardWindow$" manage=off sub-layer=below grid="$GRID_LEFT_HALF" || true
yabai -m rule --add app="^Finder$" subrole="^(AXDialog|AXSheet|AXSystemDialog|AXPopover)$" manage=off sticky=on sub-layer=above || true

# --- rules: development & productivity -------------------------------------
yabai -m rule --add app="^WezTerm$" manage=on || true
yabai -m rule --add app="^Visual Studio Code$" manage=on || true
yabai -m rule --add app="^Docker Desktop$" manage=off sub-layer=below grid="$GRID_CENTER" || true

yabai -m rule --add app="^Karabiner-Elements$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^Raycast$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^CleanShot X$" manage=off sub-layer=above || true
yabai -m rule --add app="^BetterTouchTool$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^Hammerspoon$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^1Password$" manage=off sub-layer=above sticky=on grid="$GRID_CENTER" || true

# --- rules: browsers --------------------------------------------------------
yabai -m rule --add app="^Arc$" manage=on || true
yabai -m rule --add app="^Arc$" title="^Little Arc$" manage=off sticky=on sub-layer=above || true
yabai -m rule --add app="^Arc$" subrole="^AXSystemFloatingWindow$" manage=off sticky=on sub-layer=above || true
yabai -m rule --add app="^Arc$" subrole="^AXSystemDialog$" manage=off sticky=on sub-layer=above || true
yabai -m rule --add app="^Arc Helper.*$" manage=off || true
yabai -m rule --add app="^Arc$" title=".*[Nn]otification.*" manage=off sticky=on sub-layer=above || true

# --- rules: utilities & media ----------------------------------------------
yabai -m rule --add app="^Calculator$" manage=off sub-layer=below grid="$GRID_TOP_RIGHT_QUARTER" || true
yabai -m rule --add app="^Dictionary$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^Digital Colormeter$" manage=off sub-layer=below grid="$GRID_TOP_RIGHT_QUARTER" || true
yabai -m rule --add app="^ColorSync Utility$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^Font File Browser$" manage=off sub-layer=below grid="$GRID_CENTER" || true

yabai -m rule --add app="^Preview$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^QuickTime Player$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^Spotify$" manage=off sub-layer=below grid="$GRID_RIGHT_HALF" || true

# --- rules: communication ---------------------------------------------------
yabai -m rule --add app="^Discord$" manage=off sub-layer=below grid="$GRID_RIGHT_HALF" || true
yabai -m rule --add app="^Telegram$" manage=off sub-layer=below grid="$GRID_RIGHT_HALF" || true
yabai -m rule --add app="^WhatsApp$" manage=off sub-layer=below grid="$GRID_RIGHT_HALF" || true
yabai -m rule --add app="^Messages$" role="^AXWindow$" subrole="^AXStandardWindow$" manage=off sub-layer=below grid="$GRID_RIGHT_HALF" || true
yabai -m rule --add app="^FaceTime$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^zoom.us$" manage=off sub-layer=below grid="$GRID_CENTER" || true

# --- rules: creative & design -----------------------------------------------
yabai -m rule --add app="^Blender$" manage=off sub-layer=below || true
yabai -m rule --add app="^Adobe Photoshop 202[0-9]$" manage=off sub-layer=below grid="$GRID_FULL" || true
yabai -m rule --add app="^Adobe Illustrator 202[0-9]$" manage=off sub-layer=below grid="$GRID_FULL" || true
yabai -m rule --add app="^Adobe After Effects 202[0-9]$" manage=off sub-layer=below grid="$GRID_FULL" || true
yabai -m rule --add app="^Adobe Creative Cloud$" manage=off sub-layer=below grid="$GRID_CENTER" || true

# --- rules: cloud storage & maintenance ------------------------------------
yabai -m rule --add app="^Google Drive$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^OneDrive$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^MEGAsync$" manage=off sub-layer=below grid="$GRID_CENTER" || true
yabai -m rule --add app="^CleanMyMac( X)?$" manage=off sub-layer=below || true

# --- rules: universal window types -----------------------------------------
yabai -m rule --add subrole="^AXPopover$" manage=off sticky=on sub-layer=above || true
yabai -m rule --add subrole="^AXInspector$" manage=off sticky=on sub-layer=above || true
yabai -m rule --add role="^AXWindow$" subrole="^AXUnknown$" manage=off sticky=on sub-layer=above || true
yabai -m rule --add title="(Preferences|Settings|Options|Configuration|About|Library|Queue)" manage=off sticky=on sub-layer=above || true

# --- rules: apply -----------------------------------------------------------
yabai -m rule --apply
