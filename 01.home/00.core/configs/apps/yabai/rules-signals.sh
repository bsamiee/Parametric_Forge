#!/usr/bin/env sh
# Title         : rules-signals.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/yabai/rules-signals.sh
# ----------------------------------------------------------------------------
# Yabai rules and signals module. Source from yabairc after core config
# and grid anchors are loaded. Assumes $YABAI_BIN, $JQ_BIN and GRID_* exist.

set -eu

# Ensure critical anchors exist (fallback if anchors module not loaded)
: "${GRID_RIGHT_HALF:=1:2:1:0:1:1}"
: "${GRID_CENTER:=6:6:1:1:4:4}"
: "${GRID_BOTTOM_BAND:=2:6:1:1:4:1}"

# Coordination: Yabai handles performance-critical rules/signals, Hammerspoon handles complex policies.
# Both systems work together via state files and events.

# Write current space layout mode to a temp JSON that Hammerspoon watches
"$YABAI_BIN" -m signal --remove write_layout_state >/dev/null 2>&1 || true
"$YABAI_BIN" -m signal --add label=write_layout_state \
    event=space_changed \
    action="PATH='/opt/homebrew/bin:/usr/local/bin:/run/current-system/sw/bin:'\$PATH; mode=\$(yabai -m query --spaces --space | jq -r '.type'); printf '{\"mode\":\"%s\"}\n' \"\$mode\" > /tmp/yabai_state.json" \
    || true

# Arc performance optimization - add small delay to reduce polling loops
"$YABAI_BIN" -m signal --add label=arc_performance_fix event=window_created app="^Arc$" action="sleep 0.1" || true

# Float non-interactive/small windows on creation (post-internal handling)
if command -v "$JQ_BIN" >/dev/null 2>&1; then
    "$YABAI_BIN" -m signal --add label=float_small_noninteractive \
        event=window_created action="
      PATH='/opt/homebrew/bin:/usr/local/bin:/run/current-system/sw/bin:'\$PATH; \
      info=\$($YABAI_BIN -m query --windows --window \$YABAI_WINDOW_ID); \
      is_floating=\$(echo \"\$info\" | jq -r '.\"is-floating\"'); \
      can_resize=\$(echo \"\$info\" | jq -r '.\"can-resize\"'); \
      can_move=\$(echo \"\$info\" | jq -r '.\"can-move\"'); \
      role=\$(echo \"\$info\" | jq -r '.role // \"\"'); \
      subrole=\$(echo \"\$info\" | jq -r '.subrole // \"\"'); \
      w=\$(echo \"\$info\" | jq -r '.frame.w // 0'); \
      h=\$(echo \"\$info\" | jq -r '.frame.h // 0'); \
      [ \"\$is_floating\" = 'true' ] && exit 0
      if [ \"\$can_resize\" = 'false' ] && [ \"\$can_move\" = 'false' ]; then
        $YABAI_BIN -m window \$YABAI_WINDOW_ID --toggle float; exit 0; fi
      case \"\$role:\$subrole\" in
        AXWindow:AXDialog|AXWindow:AXSheet|AXWindow:AXSystemDialog)
          $YABAI_BIN -m window \$YABAI_WINDOW_ID --toggle float; exit 0;;
      esac
      if [ \"\${w:-0}\" -lt 400 ] || [ \"\${h:-0}\" -lt 260 ]; then
        $YABAI_BIN -m window \$YABAI_WINDOW_ID --toggle float; fi
    "
else
    echo "yabai: jq not found; skipping float_small_noninteractive signal" >&2
fi

# --- spaces: normalize existing layouts ------------------------------------
# Ensure all current spaces use bsp layout; independent of any status bar.
if command -v "$JQ_BIN" >/dev/null 2>&1; then
    SPACE_DATA="$("$YABAI_BIN" -m query --spaces)"
    SPACE_COUNT=$(echo "$SPACE_DATA" | "$JQ_BIN" length)
    echo "$SPACE_DATA" | "$JQ_BIN" -r '.[].index' | while IFS= read -r space; do
        "$YABAI_BIN" -m space "$space" --layout bsp 2>/dev/null || true
    done
    echo "yabai: normalized layouts on $SPACE_COUNT spaces"
else
    echo "yabai: jq not found; skipping space normalization" >&2
fi

# --- rules: applications ----------------------------------------------------
# System Applications
"$YABAI_BIN" -m rule --add app="^System Settings$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^System Preferences$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^System Information$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^Activity Monitor$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^Archive Utility$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^Installer$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^Software Update$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^Finder$" manage=off sub-layer=below grid="$GRID_LEFT_HALF" || true
"$YABAI_BIN" -m rule --add app="^Migration Assistant$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^Disk Utility$" manage=off sub-layer=below grid="$GRID_CENTER" || true

# Utilities
"$YABAI_BIN" -m rule --add app="^Calculator$" manage=off sub-layer=below grid="$GRID_TOP_RIGHT_QUARTER" || true
"$YABAI_BIN" -m rule --add app="^Dictionary$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^Karabiner-Elements$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^QuickTime Player$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^Preview$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^CleanMyMac( X)?$" manage=off sub-layer=below || true
"$YABAI_BIN" -m rule --add app="^1Password$" manage=off sub-layer=above sticky=on grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^Digital Colormeter$" manage=off sub-layer=below grid="$GRID_TOP_RIGHT_QUARTER" || true
"$YABAI_BIN" -m rule --add app="^ColorSync Utility$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^Font File Browser$" manage=off sub-layer=below grid="$GRID_CENTER" || true

# Cloud Storage Clients (float/unmanaged)
"$YABAI_BIN" -m rule --add app="^Google Drive$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^OneDrive$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^MEGAsync$" manage=off sub-layer=below grid="$GRID_CENTER" || true

# Browsers - Arc requires comprehensive exclusion to prevent CPU performance loops
"$YABAI_BIN" -m rule --add label=arc_unmanaged app="^Arc$" manage=off || true
"$YABAI_BIN" -m rule --add label=arc_little app="^Arc$" title="^Little Arc$" manage=off sticky=on sub-layer=above || true
"$YABAI_BIN" -m rule --add label=arc_pip app="^Arc$" subrole="^AXSystemFloatingWindow$" manage=off sticky=on sub-layer=above || true
"$YABAI_BIN" -m rule --add label=arc_system_dialog app="^Arc$" subrole="^AXSystemDialog$" manage=off sticky=on sub-layer=above || true
"$YABAI_BIN" -m rule --add label=arc_helper app="^Arc Helper.*$" manage=off || true
"$YABAI_BIN" -m rule --add label=arc_notification app="^Arc$" title=".*[Nn]otification.*" manage=off sticky=on sub-layer=above || true

# Productivity / Tools
"$YABAI_BIN" -m rule --add app="^Raycast$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^CleanShot X$" manage=off sub-layer=above || true
"$YABAI_BIN" -m rule --add app="^BetterTouchTool$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^Docker Desktop$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^Hammerspoon$" manage=off sub-layer=below grid="$GRID_CENTER" || true

# Communication & Media
"$YABAI_BIN" -m rule --add app="^Discord$" manage=off sub-layer=below grid="$GRID_RIGHT_HALF" || true
"$YABAI_BIN" -m rule --add app="^Messages$" manage=off sub-layer=below grid="$GRID_RIGHT_HALF" || true
"$YABAI_BIN" -m rule --add app="^Telegram$" manage=off sub-layer=below grid="$GRID_RIGHT_HALF" || true
"$YABAI_BIN" -m rule --add app="^WhatsApp$" manage=off sub-layer=below grid="$GRID_RIGHT_HALF" || true
"$YABAI_BIN" -m rule --add app="^FaceTime$" manage=off sub-layer=below grid="$GRID_RIGHT_THIRD" || true
"$YABAI_BIN" -m rule --add app="^zoom.us$" manage=off sub-layer=below grid="$GRID_CENTER" || true
"$YABAI_BIN" -m rule --add app="^Spotify$" manage=off sub-layer=below grid="$GRID_BOTTOM_BAND" || true

# Creative & Design
"$YABAI_BIN" -m rule --add app="^Blender$" manage=off sub-layer=below || true
"$YABAI_BIN" -m rule --add label=adobe_ps app="^Adobe Photoshop 202[0-9]$" manage=off sub-layer=below grid="$GRID_FULL" || true
"$YABAI_BIN" -m rule --add label=adobe_ai app="^Adobe Illustrator 202[0-9]$" manage=off sub-layer=below grid="$GRID_FULL" || true
"$YABAI_BIN" -m rule --add label=adobe_ae app="^Adobe After Effects 202[0-9]$" manage=off sub-layer=below grid="$GRID_FULL" || true

# Development Tools
"$YABAI_BIN" -m rule --add app="^Console$" manage=off sub-layer=below || true
"$YABAI_BIN" -m rule --add app="^WezTerm$" manage=on || true
"$YABAI_BIN" -m rule --add app="^Visual Studio Code$" manage=on || true
"$YABAI_BIN" -m rule --add app="^Adobe Creative Cloud$" manage=off sub-layer=below grid="$GRID_CENTER" || true

# Scratchpad windows (special terminals/apps for quick access)
"$YABAI_BIN" -m rule --add app="^WezTerm$" title="^scratchpad$" manage=off sticky=on sub-layer=above grid=6:6:1:1:4:4 || true
"$YABAI_BIN" -m rule --add app="^Calculator$" manage=off sticky=on sub-layer=above grid="$GRID_TOP_RIGHT_QUARTER" || true

# --- rules: universal ------------------------------------------------------
"$YABAI_BIN" -m rule --add label=pip_utility subrole="^AXSystemFloatingWindow$" manage=off sticky=on sub-layer=above || true
"$YABAI_BIN" -m rule --add label=float_dialogs subrole="^AX(Dialog|Sheet)$" manage=off sub-layer=below || true
"$YABAI_BIN" -m rule --add label=float_sys_dialog subrole="^AXSystemDialog$" manage=off sub-layer=below || true
"$YABAI_BIN" -m rule --add label=float_popover subrole="^AXPopover$" manage=off sub-layer=below || true
"$YABAI_BIN" -m rule --add label=float_inspector subrole="^AXInspector$" manage=off sub-layer=below || true
"$YABAI_BIN" -m rule --add label=float_unknown role="^AXWindow$" subrole="^AXUnknown$" manage=off sub-layer=below || true
"$YABAI_BIN" -m rule --add label=float_prefs title="(Preferences|Settings|Options|Configuration|About|Library|Queue)" manage=off sub-layer=below || true
"$YABAI_BIN" -m rule --add label=float_prefs_tabs title="^(General|(Tab|Password|Website|Extension)s|AutoFill|Se(arch|curity)|Privacy|Advance)$" manage=off sub-layer=below || true

# --- rules: apply to existing ----------------------------------------------
"$YABAI_BIN" -m rule --apply
