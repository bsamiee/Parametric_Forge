#!/bin/bash
# Title         : constants.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/constants.sh
# ----------------------------------------------------------------------------
# Universal constants for SketchyBar configuration
# shellcheck disable=SC2034  # Variables sourced by other scripts

# --- Padding System ----------------------------------------------------------
export PADDINGS=4
export PADDINGS_SMALL=2

# --- Border Width System -----------------------------------------------------
export BORDER_THIN=1
export BORDER_MEDIUM=2
export BORDER_THICK=3

# --- Font System -------------------------------------------------------------
export TEXT_FONT="GeistMono Nerd Font" # Readable text (time, app names, numbers)
export SYMBOL_FONT="SF Pro"            # SF Symbols & system icons
export APP_FONT="sketchybar-app-font"  # App-specific icon library

# Universal font weights (APP_FONT only supports Regular)
export LIGHT_WEIGHT="Light"
export REGULAR_WEIGHT="Regular"
export MEDIUM_WEIGHT="Medium"
export BOLD_WEIGHT="Bold"

# Font sizes
export SIZE_SMALL=13.0
export SIZE_MEDIUM=14.0
export SIZE_LARGE=16.0
