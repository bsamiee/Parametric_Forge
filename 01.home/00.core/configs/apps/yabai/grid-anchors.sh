#!/usr/bin/env sh
# Title         : grid-anchors.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/yabai/grid-anchors.sh
# ----------------------------------------------------------------------------
# Reusable window grid anchors for yabai. Can be sourced to expose variables
# (e.g., $GRID_RIGHT_HALF) or executed as a CLI to apply an anchor.
# Usage (CLI): grid-anchors.sh <anchor> [--float] [--window <id>]

set -eu

# --- detect script name -----------------------------------------------------
SCRIPT_BASENAME=${0##*/}

# --- anchors: definitions ---------------------------------------------------
# halves
GRID_FULL="1:1:0:0:1:1"
GRID_LEFT_HALF="1:2:0:0:1:1"
GRID_RIGHT_HALF="1:2:1:0:1:1"
GRID_TOP_HALF="2:1:0:0:1:1"
GRID_BOTTOM_HALF="2:1:0:1:1:1"

# thirds
GRID_LEFT_THIRD="1:3:0:0:1:1"
GRID_MIDDLE_THIRD="1:3:1:0:1:1"
GRID_RIGHT_THIRD="1:3:2:0:1:1"
# shellcheck disable=SC2034  # Used externally
GRID_MID_THIRD="$GRID_MIDDLE_THIRD"

# two-thirds
GRID_LEFT_TWO_THIRDS="1:3:0:0:2:1"
GRID_RIGHT_TWO_THIRDS="1:3:1:0:2:1"

# quarters (2x2)
GRID_TOP_LEFT_QUARTER="2:2:0:0:1:1"
GRID_TOP_RIGHT_QUARTER="2:2:1:0:1:1"
GRID_BOTTOM_LEFT_QUARTER="2:2:0:1:1:1"
GRID_BOTTOM_RIGHT_QUARTER="2:2:1:1:1:1"

# 3x3
GRID_TOP_LEFT_3X3="3:3:0:0:1:1"
GRID_TOP_CENTER_3X3="3:3:1:0:1:1"
GRID_TOP_RIGHT_3X3="3:3:2:0:1:1"
GRID_MIDDLE_LEFT_3X3="3:3:0:1:1:1"
GRID_MIDDLE_CENTER_3X3="3:3:1:1:1:1"
GRID_MIDDLE_RIGHT_3X3="3:3:2:1:1:1"
GRID_BOTTOM_LEFT_3X3="3:3:0:2:1:1"
GRID_BOTTOM_CENTER_3X3="3:3:1:2:1:1"
GRID_BOTTOM_RIGHT_3X3="3:3:2:2:1:1"
# shellcheck disable=SC2034  # Used by rules-signals.sh
GRID_CENTER_SQUARE="$GRID_MIDDLE_CENTER_3X3"

# row-centered two-thirds (3x6 units): center 2/3 per row
GRID_TOP_CENTER_TWO_THIRDS="3:6:1:0:4:1"
GRID_MIDDLE_CENTER_TWO_THIRDS="3:6:1:1:4:1"
GRID_BOTTOM_CENTER_TWO_THIRDS="3:6:1:2:4:1"
# shellcheck disable=SC2034  # Aliases for external use
GRID_TOP_CENTER_TWO_THIRDS_ROW="$GRID_TOP_CENTER_TWO_THIRDS"
# shellcheck disable=SC2034  # Aliases for external use
GRID_MIDDLE_CENTER_TWO_THIRDS_ROW="$GRID_MIDDLE_CENTER_TWO_THIRDS"
# shellcheck disable=SC2034  # Aliases for external use
GRID_BOTTOM_CENTER_TWO_THIRDS_ROW="$GRID_BOTTOM_CENTER_TWO_THIRDS"

# row two-thirds anchored left/right (3x6 units)
GRID_TOP_LEFT_TWO_THIRDS_ROW="3:6:0:0:4:1"
GRID_TOP_RIGHT_TWO_THIRDS_ROW="3:6:2:0:4:1"
GRID_MIDDLE_LEFT_TWO_THIRDS_ROW="3:6:0:1:4:1"
GRID_MIDDLE_RIGHT_TWO_THIRDS_ROW="3:6:2:1:4:1"
GRID_BOTTOM_LEFT_TWO_THIRDS_ROW="3:6:0:2:4:1"
GRID_BOTTOM_RIGHT_TWO_THIRDS_ROW="3:6:2:2:4:1"

# if sourced (typical when loaded from yabairc), stop here
if [ "$SCRIPT_BASENAME" != "grid-anchors.sh" ]; then
  # shellcheck disable=SC2317  # Reachable when sourced
  return 0 2>/dev/null || exit 0
fi

# --- cli: apply anchor ------------------------------------------------------
find_bin() {
  n="$1"
  if command -v "$n" >/dev/null 2>&1; then
    command -v "$n"
    return 0
  fi
  for c in "/opt/homebrew/bin/$n" "/usr/local/bin/$n" "/run/current-system/sw/bin/$n"; do
    [ -x "$c" ] && {
      echo "$c"
      return 0
    }
  done
  echo "$n"
}

YABAI_BIN="${YABAI_BIN:-$(find_bin yabai)}"

ANCHOR="${1:-}"
[ -n "$ANCHOR" ] || {
  echo "Usage: $(basename "$0") <anchor> [--float] [--window <id>]" >&2
  exit 64
}
shift || true

FORCE_FLOAT=0
TARGET_FLAG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --float)
      FORCE_FLOAT=1
      shift
      ;;
    --window)
      [ $# -ge 2 ] || {
        echo "--window requires id" >&2
        exit 64
      }
      TARGET_FLAG="--window $2"
      shift 2
      ;;
    *)
      echo "unknown option: $1" >&2
      exit 64
      ;;
  esac
done

case "$ANCHOR" in
  full) GRID="$GRID_FULL" ;;
  left_half) GRID="$GRID_LEFT_HALF" ;;
  right_half) GRID="$GRID_RIGHT_HALF" ;;
  top_half) GRID="$GRID_TOP_HALF" ;;
  bottom_half) GRID="$GRID_BOTTOM_HALF" ;;
  left_third) GRID="$GRID_LEFT_THIRD" ;;
  middle_third | mid_third | middle) GRID="$GRID_MIDDLE_THIRD" ;;
  right_third) GRID="$GRID_RIGHT_THIRD" ;;
  left_two_thirds) GRID="$GRID_LEFT_TWO_THIRDS" ;;
  right_two_thirds) GRID="$GRID_RIGHT_TWO_THIRDS" ;;
  top_left_quarter) GRID="$GRID_TOP_LEFT_QUARTER" ;;
  top_right_quarter) GRID="$GRID_TOP_RIGHT_QUARTER" ;;
  bottom_left_quarter) GRID="$GRID_BOTTOM_LEFT_QUARTER" ;;
  bottom_right_quarter) GRID="$GRID_BOTTOM_RIGHT_QUARTER" ;;
  top_left_3x3) GRID="$GRID_TOP_LEFT_3X3" ;;
  top_center_3x3 | top_middle_3x3) GRID="$GRID_TOP_CENTER_3X3" ;;
  top_right_3x3) GRID="$GRID_TOP_RIGHT_3X3" ;;
  middle_left_3x3) GRID="$GRID_MIDDLE_LEFT_3X3" ;;
  middle_center_3x3 | center_square) GRID="$GRID_MIDDLE_CENTER_3X3" ;;
  middle_right_3x3) GRID="$GRID_MIDDLE_RIGHT_3X3" ;;
  bottom_left_3x3) GRID="$GRID_BOTTOM_LEFT_3X3" ;;
  bottom_center_3x3 | bottom_middle_3x3) GRID="$GRID_BOTTOM_CENTER_3X3" ;;
  bottom_right_3x3) GRID="$GRID_BOTTOM_RIGHT_3X3" ;;
  top_center_two_thirds | top_center_two_thirds_row) GRID="$GRID_TOP_CENTER_TWO_THIRDS" ;;
  middle_center_two_thirds | middle_center_two_thirds_row) GRID="$GRID_MIDDLE_CENTER_TWO_THIRDS" ;;
  bottom_center_two_thirds | bottom_center_two_thirds_row) GRID="$GRID_BOTTOM_CENTER_TWO_THIRDS" ;;
  top_left_two_thirds_row) GRID="$GRID_TOP_LEFT_TWO_THIRDS_ROW" ;;
  top_right_two_thirds_row) GRID="$GRID_TOP_RIGHT_TWO_THIRDS_ROW" ;;
  middle_left_two_thirds_row) GRID="$GRID_MIDDLE_LEFT_TWO_THIRDS_ROW" ;;
  middle_right_two_thirds_row) GRID="$GRID_MIDDLE_RIGHT_TWO_THIRDS_ROW" ;;
  bottom_left_two_thirds_row) GRID="$GRID_BOTTOM_LEFT_TWO_THIRDS_ROW" ;;
  bottom_right_two_thirds_row) GRID="$GRID_BOTTOM_RIGHT_TWO_THIRDS_ROW" ;;
  *)
    echo "unknown anchor: $ANCHOR" >&2
    exit 65
    ;;
esac

if [ "$FORCE_FLOAT" -eq 1 ]; then
  # toggle float on (no-op if already floating)
  $YABAI_BIN -m window "$TARGET_FLAG" --toggle float >/dev/null 2>&1 || true
fi

$YABAI_BIN -m window "$TARGET_FLAG" --grid "$GRID"
