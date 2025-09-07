#!/bin/bash
# Title         : colors.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/colors.sh
# ----------------------------------------------------------------------------
# Dracula color palette for SketchyBar

# --- Base Dracula Palette ---------------------------------------------------
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

# --- Semantic Color Mappings ------------------------------------------------
export BLACK=$DRACULA_BG
export WHITE=$DRACULA_FG
export DARK_GREY=$DRACULA_SELECTION
export GREY=$DRACULA_COMMENT
export CYAN=$DRACULA_CYAN
export GREEN=$DRACULA_GREEN
export ORANGE=$DRACULA_ORANGE
export PINK=$DRACULA_PINK
export PURPLE=$DRACULA_PURPLE
export RED=$DRACULA_RED
export YELLOW=$DRACULA_YELLOW

# --- Primary Transparency (90% opacity) -------------------------------------
export PRIMARY_BLACK=0xe6282a36
export PRIMARY_WHITE=0xe6f8f8f2
export PRIMARY_DARK_GREY=0xe644475a
export PRIMARY_GREY=0xe66272a4
export PRIMARY_CYAN=0xe68be9fd
export PRIMARY_GREEN=0xe650fa7b
export PRIMARY_ORANGE=0xe6ffb86c
export PRIMARY_PINK=0xe6ff79c6
export PRIMARY_PURPLE=0xe6bd93f9
export PRIMARY_RED=0xe6ff5555
export PRIMARY_YELLOW=0xe6f1fa8c

# --- Enhanced Transparency (75% opacity) ------------------------------------
export LIGHT_BLACK=0xbf282a36
export LIGHT_WHITE=0xbff8f8f2
export LIGHT_DARK_GREY=0xbf44475a
export LIGHT_GREY=0xbf6272a4
export LIGHT_CYAN=0xbf8be9fd
export LIGHT_GREEN=0xbf50fa7b
export LIGHT_ORANGE=0xbfffb86c
export LIGHT_PINK=0xbfff79c6
export LIGHT_PURPLE=0xbfbd93f9
export LIGHT_RED=0xbfff5555
export LIGHT_YELLOW=0xbff1fa8c

# --- Faint Transparency (45% opacity) ---------------------------------------
export FAINT_BLACK=0x73282a36
export FAINT_WHITE=0x73f8f8f2
export FAINT_DARK_GREY=0x7344475a
export FAINT_GREY=0x736272a4
export FAINT_CYAN=0x738be9fd
export FAINT_GREEN=0x7350fa7b
export FAINT_ORANGE=0x73ffb86c
export FAINT_PINK=0x73ff79c6
export FAINT_PURPLE=0x73bd93f9
export FAINT_RED=0x73ff5555
export FAINT_YELLOW=0x73f1fa8c

# --- Misc Colors ------------------------------------------------------------
export TRANSPARENT=0x00000000
export SHADOW_LIGHT=0x40282a36   # 25% Dracula BG
export SHADOW_HEAVY=$FAINT_BLACK # 50% Dracula BG
