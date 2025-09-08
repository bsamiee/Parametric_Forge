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
# shellcheck disable=SC2034  # Used externally

set -eu

# --- detect script name -----------------------------------------------------
SCRIPT_BASENAME=${0##*/}

# --- anchors: definitions (KISS, padding-aware via yabai) -------------------
# Default grid presets using yabai --grid semantics. For floating-window
# placements that must respect per-space padding, the CLI path below will
# compute absolute frames inside the managed work area (visible frame minus
# top/bottom/left/right padding). This avoids the common issue where floats
# placed using --grid hug the screen edge instead of the managed region
# (notably for top/bottom anchors).

# full
GRID_FULL="1:1:0:0:1:1"

# halves
GRID_LEFT_HALF="1:2:0:0:1:1"
GRID_RIGHT_HALF="1:2:1:0:1:1"

# vertical thirds (columns)
GRID_LEFT_THIRD="1:3:0:0:1:1"
GRID_MIDDLE_THIRD="1:3:1:0:1:1"
GRID_RIGHT_THIRD="1:3:2:0:1:1"
GRID_MID_THIRD="$GRID_MIDDLE_THIRD"

# quarters (2x2)
GRID_TOP_LEFT_QUARTER="2:2:0:0:1:1"
GRID_TOP_RIGHT_QUARTER="2:2:1:0:1:1"
GRID_BOTTOM_LEFT_QUARTER="2:2:0:1:1:1"
GRID_BOTTOM_RIGHT_QUARTER="2:2:1:1:1:1"

# minor positions (not edge-to-edge):
# - top / bottom: centered 2/3 width × 1/2 height bands
#   use 2 rows × 6 cols; width=4, height=1; x=1 centers horizontally
GRID_TOP_BAND="2:6:1:0:4:1"
GRID_BOTTOM_BAND="2:6:1:1:4:1"

# - center: approx 2/3 width × 2/3 height, centered
#   use 6×6; width=4, height=4; x=1, y=1
GRID_CENTER="6:6:1:1:4:4"

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
TARGET_ID=""

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
        TARGET_ID="$2"
        shift 2
        ;;
    *)
        echo "unknown option: $1" >&2
        exit 64
        ;;
    esac
done

case "$ANCHOR" in
# main
full) GRID="$GRID_FULL" ;;
left_half) GRID="$GRID_LEFT_HALF" ;;
right_half) GRID="$GRID_RIGHT_HALF" ;;
left_third) GRID="$GRID_LEFT_THIRD" ;;
middle_third | mid_third | middle) GRID="$GRID_MIDDLE_THIRD" ;;
right_third) GRID="$GRID_RIGHT_THIRD" ;;
top_left_quarter) GRID="$GRID_TOP_LEFT_QUARTER" ;;
top_right_quarter) GRID="$GRID_TOP_RIGHT_QUARTER" ;;
bottom_left_quarter) GRID="$GRID_BOTTOM_LEFT_QUARTER" ;;
bottom_right_quarter) GRID="$GRID_BOTTOM_RIGHT_QUARTER" ;;
# minors
top) GRID="$GRID_TOP_BAND" ;;
bottom) GRID="$GRID_BOTTOM_BAND" ;;
center) GRID="$GRID_CENTER" ;;
# compatibility aliases (for legacy configs)
center_large) GRID="$GRID_CENTER" ;;
bottom_center_two_thirds) GRID="$GRID_BOTTOM_BAND" ;;
*)
    echo "unknown anchor: $ANCHOR" >&2
    exit 65
    ;;
esac

# --- helpers: padding-aware placement for floats ----------------------------

# get current (selected) window id if none explicitly provided
win_id() {
    if [ -n "$TARGET_ID" ]; then
        printf '%s' "$TARGET_ID"
        return 0
    fi
    # yabai returns id of selected window
    id="$($YABAI_BIN -m query --windows --window 2>/dev/null | sed -n 's/.*"id":\s*\([0-9]\+\).*/\1/p')"
    [ -n "$id" ] && printf '%s' "$id" || printf '0'
}

cfg_val() {
    key="$1"
    val="$($YABAI_BIN -m config "$key" 2>/dev/null | tr -d '\n' || true)"
    case "$val" in
        ''|*[!0-9]*) echo 0;;
        *) echo "$val";;
    esac
}

is_floating() {
    wid="$(win_id)"
    [ "$wid" = 0 ] && return 1
    flg="$($YABAI_BIN -m query --windows --window "$wid" 2>/dev/null | sed -n 's/.*"is-floating":\s*\(true\|false\).*/\1/p')"
    [ "$flg" = "true" ]
}

work_area_for_win() {
    wid="$(win_id)"
    [ "$wid" = 0 ] && return 1
    # get display id for window
    did="$($YABAI_BIN -m query --windows --window "$wid" 2>/dev/null | sed -n 's/.*"display":\s*\([0-9]\+\).*/\1/p')"
    [ -z "$did" ] && did="focused"
    # display visible frame
    frame_json="$($YABAI_BIN -m query --displays --display "$did" 2>/dev/null)"
    fx=$(printf '%s' "$frame_json" | sed -n 's/.*"x":\s*\(-\?[0-9]\+\).*/\1/p' | head -n1)
    fy=$(printf '%s' "$frame_json" | sed -n 's/.*"y":\s*\(-\?[0-9]\+\).*/\1/p' | head -n1)
    fw=$(printf '%s' "$frame_json" | sed -n 's/.*"w":\s*\([0-9]\+\).*/\1/p' | head -n1)
    fh=$(printf '%s' "$frame_json" | sed -n 's/.*"h":\s*\([0-9]\+\).*/\1/p' | head -n1)
    [ -z "$fx$fy$fw$fh" ] && return 1

    # space padding (global if not overridden)
    tp=$(cfg_val top_padding)
    bp=$(cfg_val bottom_padding)
    lp=$(cfg_val left_padding)
    rp=$(cfg_val right_padding)

    # managed work area (exclude space paddings)
    wx=$((fx + lp))
    wy=$((fy + tp))
    ww=$((fw - lp - rp))
    wh=$((fh - tp - bp))
    printf '%s %s %s %s' "$wx" "$wy" "$ww" "$wh"
}

place_inside_work_area() {
    # args: target_w target_h alignX(0..1) alignY(0..1)
    tw=$1; th=$2; ax=$3; ay=$4
    set -- $(work_area_for_win) || return 1
    wx=$1; wy=$2; ww=$3; wh=$4
    # clamp sizes
    [ "$tw" -gt "$ww" ] && tw=$ww
    [ "$th" -gt "$wh" ] && th=$wh
    # center then align
    ox=$(( (ww - tw) / 2 ))
    oy=$(( (wh - th) / 2 ))
    # align factors: 0 left/top, 0.5 center, 1 right/bottom
    # compute shift relative to center
    sx=$(awk -v a="$ax" -v ww="$ww" -v tw="$tw" 'BEGIN { printf("%d", (a-0.5)*(ww-tw)) }')
    sy=$(awk -v a="$ay" -v wh="$wh" -v th="$th" 'BEGIN { printf("%d", (a-0.5)*(wh-th)) }')
    nx=$((wx + ox + sx))
    ny=$((wy + oy + sy))
    printf '%s %s %s %s' "$nx" "$ny" "$tw" "$th"
}

apply_padding_aware() {
    wid="$(win_id)"
    [ "$wid" = 0 ] && return 1
    # ensure floating when requested
    if [ "$FORCE_FLOAT" -eq 1 ] && ! is_floating; then
        $YABAI_BIN -m window "$wid" --toggle float >/dev/null 2>&1 || true
    fi

    # choose target box based on anchor
    case "$ANCHOR" in
        top)
            # 2/3 width, 1/2 height, aligned top-center
            set -- $(work_area_for_win) || return 1
            ww=$3; wh=$4
            tw=$(( ww * 4 / 6 ))
            th=$(( wh / 2 ))
            set -- $(place_inside_work_area "$tw" "$th" 0.5 0.0) || return 1
            ;;
        bottom)
            # 2/3 width, 1/2 height, aligned bottom-center
            set -- $(work_area_for_win) || return 1
            ww=$3; wh=$4
            tw=$(( ww * 4 / 6 ))
            th=$(( wh / 2 ))
            set -- $(place_inside_work_area "$tw" "$th" 0.5 1.0) || return 1
            ;;
        center)
            # 2/3 width, 2/3 height, centered
            set -- $(work_area_for_win) || return 1
            ww=$3; wh=$4
            tw=$(( ww * 4 / 6 ))
            th=$(( wh * 4 / 6 ))
            set -- $(place_inside_work_area "$tw" "$th" 0.5 0.5) || return 1
            ;;
        *)
            return 1
            ;;
    esac

    nx=$1; ny=$2; tw=$3; th=$4
    $YABAI_BIN -m window "$wid" --move abs:"$nx":"$ny" --resize abs:"$tw":"$th"
}

# If we know this anchor benefits from padding-aware placement and the window
# is floating (or we were asked to float it), use absolute placement computed
# from the managed work area. Otherwise, fall back to the simple grid.
case "$ANCHOR" in
    top|bottom|center)
        if is_floating || [ "$FORCE_FLOAT" -eq 1 ]; then
            apply_padding_aware || $YABAI_BIN -m window "$TARGET_FLAG" --grid "$GRID"
        else
            $YABAI_BIN -m window "$TARGET_FLAG" --grid "$GRID"
        fi
        ;;
    *)
        if [ "$FORCE_FLOAT" -eq 1 ]; then
            $YABAI_BIN -m window "$TARGET_FLAG" --toggle float >/dev/null 2>&1 || true
        fi
        $YABAI_BIN -m window "$TARGET_FLAG" --grid "$GRID"
        ;;
esac
