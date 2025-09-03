#!/bin/bash
# Title         : controls.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/controls.sh
# ----------------------------------------------------------------------------
# Menu bar controls and toggle system handler
# shellcheck disable=SC1091

# --- Configuration --------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Event Handling -------------------------------------------------------
case "$NAME" in
    "control_center")
        controls_string="$1"

        # Convert space-delimited string to array
        IFS=' ' read -ra controls_array <<< "$controls_string"

        case "$SENDER" in
            "mouse.clicked")
                handle_toggle_state "$NAME" "$CONTROL_CENTER" "$SEPARATOR_LINE" "${controls_array[@]}"
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
