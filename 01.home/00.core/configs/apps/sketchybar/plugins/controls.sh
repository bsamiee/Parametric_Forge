#!/bin/bash
# Title         : controls.sh
# Author        : Bardia Samiee (adapted from reference)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/controls.sh
# ----------------------------------------------------------------------------
# Menu bar controls and toggle system handler
# shellcheck disable=SC1091

# --- Load Configuration Variables -------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"


# --- Handle Different Item Types --------------------------------------------
case "$NAME" in
    "more_menu")
        # Parse arguments: controls_string
        controls_string="$1"

        # Convert space-delimited string to array
        IFS=' ' read -ra controls_array <<< "$controls_string"

        case "$SENDER" in
            "mouse.clicked")
                handle_toggle_state "$NAME" "􀯶" "|" "${controls_array[@]}"
                ;;
            "mouse.entered"|"mouse.exited")
                handle_mouse_event "$NAME" "$SENDER"
                ;;
        esac
        ;;
    *)
        # Handle regular menu item clicks
        case "$SENDER" in
            "mouse.clicked")
                menubar -s "$NAME"
                ;;
            "mouse.entered"|"mouse.exited")
                handle_mouse_event "$NAME" "$SENDER"
                ;;
        esac
        ;;
esac
