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

# --- Primary Transparency (95% opacity) -------------------------------------
export PRIMARY_BLACK=0xf2282a36
export PRIMARY_WHITE=0xf2f8f8f2
export PRIMARY_DARK_GREY=0xf244475a
export PRIMARY_GREY=0xf26272a4
export PRIMARY_CYAN=0xf28be9fd
export PRIMARY_GREEN=0xf250fa7b
export PRIMARY_ORANGE=0xf2ffb86c
export PRIMARY_PINK=0xf2ff79c6
export PRIMARY_PURPLE=0xf2bd93f9
export PRIMARY_RED=0xf2ff5555
export PRIMARY_YELLOW=0xf2f1fa8c

# --- Enhanced Transparency (80% opacity) ------------------------------------
export LIGHT_BLACK=0xcc282a36
export LIGHT_WHITE=0xccf8f8f2
export LIGHT_DARK_GREY=0xcc44475a
export LIGHT_GREY=0xcc6272a4
export LIGHT_CYAN=0xcc8be9fd
export LIGHT_GREEN=0xcc50fa7b
export LIGHT_ORANGE=0xccffb86c
export LIGHT_PINK=0xccff79c6
export LIGHT_PURPLE=0xccbd93f9
export LIGHT_RED=0xccff5555
export LIGHT_YELLOW=0xccf1fa8c

# --- Faint Transparency (50% opacity) ---------------------------------------
export FAINT_BLACK=0x80282a36
export FAINT_WHITE=0x80f8f8f2
export FAINT_DARK_GREY=0x8044475a
export FAINT_GREY=0x806272a4
export FAINT_CYAN=0x808be9fd
export FAINT_GREEN=0x8050fa7b
export FAINT_ORANGE=0x80ffb86c
export FAINT_PINK=0x80ff79c6
export FAINT_PURPLE=0x80bd93f9
export FAINT_RED=0x80ff5555
export FAINT_YELLOW=0x80f1fa8c

# --- Misc Colors ------------------------------------------------------------
export TRANSPARENT=0x00000000
export SHADOW_LIGHT=0x40282a36   # 25% Dracula BG
export SHADOW_HEAVY=$FAINT_BLACK # 50% Dracula BG
