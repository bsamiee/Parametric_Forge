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

# Ensure YABAI_BIN is available (fallback if not sourced from yabairc)
: "${YABAI_BIN:=yabai}"

# Ensure critical anchors exist (fallback if anchors module not loaded)
: "${GRID_FULL:=1:1:0:0:1:1}"
: "${GRID_LEFT_HALF:=1:2:0:0:1:1}"
: "${GRID_RIGHT_HALF:=1:2:1:0:1:1}"
: "${GRID_RIGHT_THIRD:=1:3:2:0:1:1}"
: "${GRID_TOP_RIGHT_QUARTER:=2:2:1:0:1:1}"
: "${GRID_CENTER:=6:6:1:1:4:4}"
# Keep fallback consistent with grid-anchors.sh to avoid edge-hugging
: "${GRID_BOTTOM_BAND:=6:6:1:4:4:1}"

# Consolidated state writer script (used by all signals)
# Includes space label for consumers that present richer context.
WRITE_STATE_ACTION="PATH='/opt/homebrew/bin:/usr/local/bin:/run/current-system/sw/bin:'\\\$PATH; \
idx=\\\$(yabai -m query --spaces --space | jq -r '.index // 0' 2>/dev/null || printf '0'); \
mode=\\\$(yabai -m query --spaces --space | jq -r '.type // \\\"?\\\"' 2>/dev/null || printf '?'); \
label=\\\$(yabai -m query --spaces --space | jq -r '.label // \\\"\\\"' 2>/dev/null || printf ''); \
disp=\\\$(yabai -m query --spaces --space | jq -r '.display // 0' 2>/dev/null || printf '0'); \
count=\\\$(yabai -m query --spaces --display \\\"\\\$disp\\\" | jq 'map(select(.[\\\"is-native-fullscreen\\\"] == false)) | length' 2>/dev/null || printf '0'); \
gaps=\\\$(yabai -m config top_padding 2>/dev/null | tr -d '\\n' || printf '0'); \
drop=\\\$(yabai -m config mouse_drop_action 2>/dev/null | tr -d '\\n' || printf 'swap'); \
[ -z \\\"\\\$drop\\\" ] && drop=swap; \
op=\\\$(yabai -m config window_opacity 2>/dev/null | tr -d '\\n' || printf 'off'); \
[ -z \\\"\\\$op\\\" ] && op=off; \
sa=no; [ -d /Library/ScriptingAdditions/yabai.osax ] && sa=yes; \
printf '{\\\"mode\\\":\\\"%s\\\",\\\"idx\\\":%s,\\\"label\\\":\\\"%s\\\",\\\"count\\\":%s,\\\"gaps\\\":%s,\\\"drop\\\":\\\"%s\\\",\\\"opacity\\\":\\\"%s\\\",\\\"sa\\\":\\\"%s\\\"}\\n' \\\"\\\$mode\\\" \\\"\\\$idx\\\" \\\"\\\$label\\\" \\\"\\\$count\\\" \\\"\\\$gaps\\\" \\\"\\\$drop\\\" \\\"\\\$op\\\" \\\"\\\$sa\\\" > \${TMPDIR:-/tmp}/yabai_state.json"

# Register consolidated state signals (all write complete state)
"$YABAI_BIN" -m signal --remove write_state_space >/dev/null 2>&1 || true
"$YABAI_BIN" -m signal --add label=write_state_space event=space_changed action="$WRITE_STATE_ACTION" || true

"$YABAI_BIN" -m signal --remove write_state_display >/dev/null 2>&1 || true
"$YABAI_BIN" -m signal --add label=write_state_display event=display_changed action="$WRITE_STATE_ACTION" || true

"$YABAI_BIN" -m signal --remove write_state_mc >/dev/null 2>&1 || true
"$YABAI_BIN" -m signal --add label=write_state_mc event=mission_control_exit action="$WRITE_STATE_ACTION" || true

# Arc performance optimization - add small delay to reduce polling loops
"$YABAI_BIN" -m signal --remove arc_performance_fix >/dev/null 2>&1 || true
"$YABAI_BIN" -m signal --add label=arc_performance_fix event=window_created app="^Arc$" action="sleep 0.1" || true

# Float non-interactive/small windows on creation (post-internal handling)
if command -v "$JQ_BIN" >/dev/null 2>&1; then
    "$YABAI_BIN" -m signal --remove float_small_noninteractive >/dev/null 2>&1 || true
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
"$YABAI_BIN" -m rule --add label=finder_main app="^Finder$" role="^AXWindow$" subrole="^AXStandardWindow$" manage=off sub-layer=below grid="$GRID_LEFT_HALF" || true
"$YABAI_BIN" -m rule --add label=finder_transients app="^Finder$" subrole="^(AXDialog|AXSheet|AXSystemDialog|AXPopover)$" manage=off sticky=on sub-layer=above || true
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
"$YABAI_BIN" -m rule --add label=messages_main app="^Messages$" role="^AXWindow$" subrole="^AXStandardWindow$" manage=off sub-layer=below grid="$GRID_RIGHT_HALF" || true
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

# --- rules: universal ------------------------------------------------------
"$YABAI_BIN" -m rule --add label=pip_utility subrole="^AXSystemFloatingWindow$" manage=off sticky=on sub-layer=above || true
"$YABAI_BIN" -m rule --add label=float_dialogs subrole="^AX(Dialog|Sheet)$" manage=off sticky=on sub-layer=above || true
"$YABAI_BIN" -m rule --add label=float_sys_dialog subrole="^AXSystemDialog$" manage=off sticky=on sub-layer=above || true
"$YABAI_BIN" -m rule --add label=float_popover subrole="^AXPopover$" manage=off sticky=on sub-layer=above || true
"$YABAI_BIN" -m rule --add label=float_inspector subrole="^AXInspector$" manage=off sticky=on sub-layer=above || true
"$YABAI_BIN" -m rule --add label=float_unknown role="^AXWindow$" subrole="^AXUnknown$" manage=off sticky=on sub-layer=above || true
"$YABAI_BIN" -m rule --add label=float_prefs title="(Preferences|Settings|Options|Configuration|About|Library|Queue)" manage=off sticky=on sub-layer=above || true
"$YABAI_BIN" -m rule --add label=float_prefs_tabs title="^(General|(Tab|Password|Website|Extension)s|AutoFill|Se(arch|curity)|Privacy|Advance)$" manage=off sticky=on sub-layer=above || true

# Common file panels across apps (Open/Save/Attach/Export/Import/Choose)
"$YABAI_BIN" -m rule --add label=float_file_panels title="^(Open|Save|Choose|Attach|Export|Import|Share|Upload|Download).*" subrole="^(AXDialog|AXSheet)$" manage=off sticky=on sub-layer=above || true

# --- rules: apply to existing ----------------------------------------------
"$YABAI_BIN" -m rule --apply
