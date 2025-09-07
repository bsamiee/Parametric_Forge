#!/bin/bash
# Title         : constants.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/constants.sh
# ----------------------------------------------------------------------------
# Universal constants for SketchyBar configuration
# shellcheck disable=SC2034  # Variables sourced by other scripts

# --- Padding System ---------------------------------------------------------
export PADDINGS_NONE=0
export PADDINGS_SMALL=2
export PADDINGS_MEDIUM=4
export PADDINGS_LARGE=8
export PADDINGS_XLARGE=12
export PADDINGS_XXLARGE=16

# --- Offsets & Effects ------------------------------------------------------
export OFFSET_BAR=4
export OFFSET_ICON_BG=-12

export SHADOW_DISTANCE=3
export SHADOW_ANGLE=30

export BLUR_RADIUS_STANDARD=20

# --- Border Width System ----------------------------------------------------
export BORDER_NONE=0
export BORDER_THIN=1
export BORDER_MEDIUM=2
export BORDER_THICK=3

# --- Corner Radius System ---------------------------------------------------
export RADIUS_SMALL=4
export RADIUS_MEDIUM=8
export RADIUS_LARGE=16

# --- Dimensions System ------------------------------------------------------
export HEIGHT_BAR=36

export HEIGHT_ITEM=26
export HEIGHT_ICON_BG=2

export ICON_WIDTH_STANDARD=30

# --- Font System ------------------------------------------------------------
export TEXT_FONT="GeistMono Nerd Font"             # Readable text (time, app names, numbers)
export SYMBOL_FONT="SF Symbols"                    # SF Symbols & system icons
export APP_FONT="sketchybar-app-font:Regular:12.0" # App-specific icon library

# Universal font weights (APP_FONT only supports Regular)
export LIGHT_WEIGHT="Light"
export REGULAR_WEIGHT="Regular"
export MEDIUM_WEIGHT="Medium"
export BOLD_WEIGHT="Bold"

# Font sizes
export SIZE_XSMALL=8.0
export SIZE_SMALL=10.0
export SIZE_MEDIUM=12.0
export SIZE_LARGE=16.0

# --- Battery Behavior -------------------------------------------------------
# Sailing range: how far below the set limit charging resumes (in percent)
export SAILING_RANGE=${SAILING_RANGE:-5}

# Temperature Guard (sane defaults, always-on battery protection)
# When temperature >= TEMP_GUARD_MAX_C, pause charging (adapter off) until <= TEMP_GUARD_RESUME_C
# Never force discharge below TEMP_GUARD_MIN_PERCENT to avoid deep discharge when hot
export TEMP_GUARD_ENABLED=${TEMP_GUARD_ENABLED:-1}
export TEMP_GUARD_MAX_C=${TEMP_GUARD_MAX_C:-40}
export TEMP_GUARD_RESUME_C=${TEMP_GUARD_RESUME_C:-38}
export TEMP_GUARD_MIN_PERCENT=${TEMP_GUARD_MIN_PERCENT:-40}
