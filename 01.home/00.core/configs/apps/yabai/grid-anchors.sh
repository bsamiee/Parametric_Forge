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
# - `yabai` and `jq` are available in PATH
# - We operate on the focused window unless --window <id> is provided
#
# shellcheck disable=SC2034  # Variables are exported when sourced

set -eu

# --- anchors: definitions ---------------------------------------------------
# Use yabai --grid semantics; yabai respects per-space padding so no math here.
GRID_FULL="1:1:0:0:1:1"
GRID_LEFT_HALF="1:2:0:0:1:1"
GRID_RIGHT_HALF="1:2:1:0:1:1"
GRID_LEFT_THIRD="1:3:0:0:1:1"
GRID_MIDDLE_THIRD="1:3:1:0:1:1"
GRID_RIGHT_THIRD="1:3:2:0:1:1"
GRID_TOP_LEFT_QUARTER="2:2:0:0:1:1"
GRID_TOP_RIGHT_QUARTER="2:2:1:0:1:1"
GRID_BOTTOM_LEFT_QUARTER="2:2:0:1:1:1"
GRID_BOTTOM_RIGHT_QUARTER="2:2:1:1:1:1"
GRID_CENTER="6:6:1:1:4:4"

# --- CLI (wrapped in main, called only when executed) ----------------------
main() {
  YABAI_BIN="${YABAI_BIN:-yabai}"
  JQ_BIN="${JQ_BIN:-jq}"

  ANCHOR=${1:?"Usage: $(basename "$0") <anchor> [--float] [--window <id>]"}
  shift || true

  FORCE_FLOAT=0
  WIN_ID=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --float) FORCE_FLOAT=1; shift ;;
      --window) WIN_ID=${2:?"--window requires id"}; shift 2 ;;
      *) echo "unknown option: $1" >&2; exit 64 ;;
    esac
  done

  case "$ANCHOR" in
    full) GRID=$GRID_FULL ;;
    left_half) GRID=$GRID_LEFT_HALF ;;
    right_half) GRID=$GRID_RIGHT_HALF ;;
    left_third) GRID=$GRID_LEFT_THIRD ;;
    middle_third|middle) GRID=$GRID_MIDDLE_THIRD ;;
    right_third) GRID=$GRID_RIGHT_THIRD ;;
    top_left_quarter) GRID=$GRID_TOP_LEFT_QUARTER ;;
    top_right_quarter) GRID=$GRID_TOP_RIGHT_QUARTER ;;
    bottom_left_quarter) GRID=$GRID_BOTTOM_LEFT_QUARTER ;;
    bottom_right_quarter) GRID=$GRID_BOTTOM_RIGHT_QUARTER ;;
    top) GRID=$GRID_RIGHT_HALF ;;
    bottom) GRID=$GRID_RIGHT_HALF ;;
    center) GRID=$GRID_CENTER ;;
    *) echo "unknown anchor: $ANCHOR" >&2; exit 65 ;;
  esac

  # Focus the requested window id if provided (best effort)
  if [ -n "$WIN_ID" ]; then
    "$YABAI_BIN" -m window --focus "$WIN_ID" >/dev/null 2>&1 || true
  fi

  # Toggle float only if not already floating (idempotent)
  if [ "$FORCE_FLOAT" -eq 1 ]; then
    if [ -n "$WIN_ID" ]; then
      INFO=$("$YABAI_BIN" -m query --windows --window "$WIN_ID")
    else
      INFO=$("$YABAI_BIN" -m query --windows --window)
    fi
    IS_FLOATING=$(printf %s "$INFO" | "$JQ_BIN" -r '."is-floating"')
    if [ "$IS_FLOATING" != "true" ]; then
      "$YABAI_BIN" -m window --toggle float >/dev/null 2>&1 || true
    fi
  fi

  "$YABAI_BIN" -m window --grid "$GRID"
}

# Only run CLI when executed directly; when sourced, just export variables.
if [ "${0##*/}" = "grid-anchors.sh" ]; then
  # Use run-yabai.sh for consistent PATH resolution
  YABAI_BIN="${YABAI_BIN:-$HOME/.config/yabai/run-yabai.sh}"
  JQ_BIN="${JQ_BIN:-jq}"
  main "$@"
fi
