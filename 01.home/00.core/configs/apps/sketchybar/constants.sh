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
export PADDINGS=4
export PADDINGS_SMALL=2
export PADDINGS_LARGE=8
export PADDINGS_XLARGE=12
export PADDINGS_XXLARGE=16
export PADDINGS_NONE=0


# --- Offsets & Effects ------------------------------------------------------
export OFFSET_BAR=4
export OFFSET_ICON_BG=-12
export SHADOW_DISTANCE=3
export SHADOW_ANGLE=30
export BLUR_RADIUS_STANDARD=20

# --- Border Width System ----------------------------------------------------
export BORDER_THIN=1
export BORDER_MEDIUM=2
export BORDER_THICK=3

# --- Corner Radius System ---------------------------------------------------
export RADIUS_SMALL=4
export RADIUS_MEDIUM=8
export RADIUS_LARGE=16

# --- Height System ----------------------------------------------------------
export HEIGHT_ITEM=26
export HEIGHT_BAR=36
export HEIGHT_ICON_BG=2

# --- Icon Dimensions --------------------------------------------------------
export ICON_WIDTH_STANDARD=30

# --- Font System ------------------------------------------------------------
export TEXT_FONT="GeistMono Nerd Font"             # Readable text (time, app names, numbers)
export SYMBOL_FONT="SF Pro"                        # SF Symbols & system icons
export APP_FONT="sketchybar-app-font:Regular:10.0" # App-specific icon library

# Universal font weights (APP_FONT only supports Regular)
export LIGHT_WEIGHT="Light"
export REGULAR_WEIGHT="Regular"
export MEDIUM_WEIGHT="Medium"
export BOLD_WEIGHT="Bold"

# Font sizes
export SIZE_XSMALL=6.0
export SIZE_SMALL=8.0
export SIZE_MEDIUM=10.0
export SIZE_LARGE=14.0
