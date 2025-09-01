#!/bin/bash
# Title         : colors.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/colors.sh
# ----------------------------------------------------------------------------
# Dracula color palette for SketchyBar - consistent with ecosystem theme

# --- Dracula Core Palette ------------------------------------------------
export DRACULA_BG=0xff282a36
export DRACULA_FG=0xfff8f8f2
export DRACULA_SELECTION=0xff44475a
export DRACULA_COMMENT=0xff6272a4
export DRACULA_CYAN=0xff8be9fd
export DRACULA_GREEN=0xff50fa7b
export DRACULA_ORANGE=0xffffb86c
export DRACULA_PINK=0xffff79c6
export DRACULA_PURPLE=0xffbd93f9
export DRACULA_RED=0xffff5555
export DRACULA_YELLOW=0xfff1fa8c

# --- SketchyBar Semantic Colors (Transparency-Integrated) ---------------
export BAR_COLOR=0xcc282a36 # 80% opacity - floating aesthetic
export ICON_COLOR=$DRACULA_FG
export LABEL_COLOR=$DRACULA_FG
export TRANSPARENT=0x00000000

# Item backgrounds (harmonized with ecosystem transparency)
export BG_PRIMARY=0xdd6272a4 # 87% comment - readable yet integrated
export BG_ACTIVE=0xddbd93f9  # 87% purple - maintains vibrancy  
export BG_SUCCESS=0xdd50fa7b # 87% green - success visibility
export BG_WARNING=0xddffb86c # 87% orange - warning clarity
export BG_ERROR=0xddff5555   # 87% red - error prominence
export BG_INFO=0xdd8be9fd    # 87% cyan - information calm

# --- Widget State Colors (Extended for Enhanced Functionality) ------------
export SPACE_ACTIVE_ICON=$DRACULA_BG      # Dark icon on bright background
export SPACE_ACTIVE_BG=$DRACULA_PURPLE    # Active space background
export SPACE_OCCUPIED_ICON=$DRACULA_CYAN  # Cyan for spaces with windows
export SPACE_OCCUPIED_BG=$BG_INFO         # Semi-transparent cyan background
export SPACE_EMPTY_ICON=$DRACULA_COMMENT  # Subtle comment color for empty spaces
export SPACE_EMPTY_BG=$TRANSPARENT        # Transparent background for empty spaces

# --- Future Widget Colors (Ready for Phase 2) ----------------------------
export SYSTEM_CPU_COLOR=$DRACULA_RED      # CPU usage indicator
export SYSTEM_MEM_COLOR=$DRACULA_YELLOW   # Memory usage indicator  
export SYSTEM_DISK_COLOR=$DRACULA_ORANGE  # Disk usage indicator
export BATTERY_NORMAL_COLOR=$DRACULA_GREEN # Battery normal state
export BATTERY_LOW_COLOR=$DRACULA_ORANGE  # Battery warning state
export BATTERY_CRITICAL_COLOR=$DRACULA_RED # Battery critical state
export AUDIO_NORMAL_COLOR=$DRACULA_CYAN   # Audio normal state
export AUDIO_MUTED_COLOR=$DRACULA_COMMENT # Audio muted state

# --- Transparency Variants -----------------------------------------------
export TRANSPARENT=0x00000000
export BG_SEMI=0x80282a36 # Semi-transparent background

# --- System Integration Colors -------------------------------------------
export BORDER_COLOR=$DRACULA_SELECTION
export SHADOW_COLOR=0x40000000 # Subtle shadow

