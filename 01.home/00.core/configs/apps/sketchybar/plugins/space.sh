#!/bin/bash
# Title         : space.sh
# Author        : Bardia Samiee (adapted from FelixKratz)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/space.sh
# ----------------------------------------------------------------------------
# Space item update plugin - handles focus changes

set -euo pipefail

# Load theme colors
# shellcheck disable=SC1091
source "$HOME/.config/sketchybar/colors.sh"

# The $SELECTED variable indicates if this space is currently focused
# $NAME contains the space item name (e.g., "space.1")

if [ "$SELECTED" = "true" ]; then
    # Active space - highlight with purple background
    sketchybar --set "$NAME" \
        icon.color="$DRACULA_BG" \
        background.color="$DRACULA_PURPLE" \
        background.drawing=on
else
    # Inactive space - subtle comment color background
    sketchybar --set "$NAME" \
        icon.color="$DRACULA_FG" \
        background.color="$DRACULA_COMMENT" \
        background.drawing=on
fi
