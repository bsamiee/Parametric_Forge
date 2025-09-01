#!/bin/bash
# Title         : space.sh
# Author        : Bardia Samiee (adapted from FelixKratz)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/helpers/space.sh
# ----------------------------------------------------------------------------
# Enhanced space item update plugin - handles focus changes and window states

set -euo pipefail

# Load theme colors
# shellcheck disable=SC1091
source "$HOME/.config/sketchybar/colors.sh"

# Environment variables provided by SketchyBar:
# $SELECTED - "true" if this space is currently focused
# $NAME - space item name (e.g., "space.1") 
# $SID - space ID for yabai queries

# --- Window State Detection -----------------------------------------------
# Query yabai for windows on this space (requires jq)
if command -v jq >/dev/null 2>&1; then
    WINDOWS=$(yabai -m query --spaces --space "$SID" 2>/dev/null | jq '.windows[]?' 2>/dev/null | wc -l | tr -d ' ')
    HAS_WINDOWS=$([[ "$WINDOWS" -gt 0 ]] && echo "true" || echo "false")
else
    # Fallback if jq unavailable - assume has windows if not hidden
    HAS_WINDOWS="true"
fi

# --- Visual State Logic ---------------------------------------------------
if [ "$SELECTED" = "true" ]; then
    # Active space - prominent purple with dark icon
    ICON_COLOR="$DRACULA_BG"
    BG_COLOR="$DRACULA_PURPLE" 
    ICON="●"
elif [ "$HAS_WINDOWS" = "true" ]; then
    # Inactive space with windows - cyan accent
    ICON_COLOR="$DRACULA_CYAN"
    BG_COLOR="$BG_INFO"
    ICON="●"
else
    # Empty space - subtle comment styling
    ICON_COLOR="$DRACULA_COMMENT" 
    BG_COLOR="$TRANSPARENT"
    ICON="○"
fi

# --- Apply Visual State ---------------------------------------------------
sketchybar --set "$NAME" \
    icon="$ICON" \
    icon.color="$ICON_COLOR" \
    background.color="$BG_COLOR" \
    background.drawing=on
