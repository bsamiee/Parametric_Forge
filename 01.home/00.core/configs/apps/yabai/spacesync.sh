#!/bin/bash
# Title         : spacesync.sh
# Author        : Bardia Samiee  
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/yabai/spacesync.sh
# ----------------------------------------------------------------------------
# Clean space synchronization between yabai and SketchyBar

set -euo pipefail

source "$HOME/.config/sketchybar/colors.sh"

# --- Get Current Spaces --------------------------------------------------
SPACES=$(yabai -m query --spaces 2>/dev/null | jq -r '.[].index' | sort -n)

if [ -z "$SPACES" ]; then
    echo "[spacesync] No spaces found"
    exit 1
fi

TOTAL_SPACES=$(echo "$SPACES" | wc -w | tr -d ' ')
echo "[spacesync] Syncing $TOTAL_SPACES spaces"

# --- Clean Slate ---------------------------------------------------------
# Remove all potential space items (handles any orphaned items)
for i in {1..10}; do
    sketchybar --remove "space.$i" 2>/dev/null || true
done

# --- Create Space Items --------------------------------------------------
for space in $SPACES; do
    sketchybar --add space "space.$space" left \
        --set "space.$space" \
        space="$space" \
        icon="$space" \
        icon.font="GeistMono Nerd Font:Medium:14.0" \
        icon.color="$ICON_COLOR" \
        icon.padding_left=8 \
        icon.padding_right=8 \
        label.drawing=off \
        background.corner_radius=6 \
        background.height=28 \
        padding_left=3 \
        padding_right=3 \
        click_script="yabai -m space --focus $space" \
        script="$HOME/.config/sketchybar/helpers/space.sh" \
        --subscribe "space.$space" windows_on_spaces
done

echo "[spacesync] ✓ Synchronized $TOTAL_SPACES spaces"

# Update state for ecosystem integration
echo "{\"spaces\":$TOTAL_SPACES,\"mode\":\"windowed\"}" > /tmp/yabai_state.json

