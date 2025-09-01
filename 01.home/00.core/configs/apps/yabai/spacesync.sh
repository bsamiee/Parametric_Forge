#!/bin/bash
# Title         : spacesync.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/yabai/spacesync.sh
# ----------------------------------------------------------------------------
# Adaptive space synchronization between yabai and SketchyBar

set -euo pipefail

# Load SketchyBar theme colors
# shellcheck disable=SC1091
source "$HOME/.config/sketchybar/colors.sh"

# --- Dynamic Space Synchronization -----------------------------------------
# Get actual spaces from yabai (only existing ones)
SPACES=$(yabai -m query --spaces 2>/dev/null | jq -r '.[].index' | sort -n)

if [ -z "$SPACES" ]; then
    echo "[spacesync] No spaces found"
    exit 1
fi

echo "[spacesync] Syncing $(echo "$SPACES" | wc -w | tr -d ' ') actual spaces"

# Remove all potential space items (clean slate)
for i in {1..9}; do
    sketchybar --remove "space.$i" 2>/dev/null || true
done

# Add items only for existing spaces
for space in $SPACES; do
    sketchybar --add space "space.$space" left \
        --set "space.$space" \
        space="$space" \
        icon="$space" \
        icon.color="$ICON_COLOR" \
        background.color="$BG_PRIMARY" \
        background.corner_radius=6 \
        background.height=28 \
        padding_left=5 \
        padding_right=5 \
        click_script="yabai -m space --focus $space" \
        script="$HOME/.config/sketchybar/plugins/space.sh"
done

echo "[spacesync] Synchronized SketchyBar with $(echo "$SPACES" | wc -w | tr -d ' ') spaces"

# Update ecosystem state
TOTAL_SPACES=$(echo "$SPACES" | wc -w | tr -d ' ')
echo "{\"padding\":4,\"gap\":4,\"mode\":\"windowed\",\"spaces\":$TOTAL_SPACES}" >/tmp/yabai_state.json

