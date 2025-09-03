#!/bin/bash
# Title         : mic.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/mic.sh
# ----------------------------------------------------------------------------
# Microphone control with volume-based visual states and toggle functionality
# shellcheck disable=SC1091

# --- Configuration --------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Volume Detection -----------------------------------------------------
get_mic_volume() {
    osascript -e 'set ivol to input volume of (get volume settings)' 2>/dev/null || echo "0"
}

# --- Icon Update ----------------------------------------------------------
update_icon() {
    local volume icon color
    volume=$(get_mic_volume)

    # Set icon and color based on volume level
    case "$volume" in
        [6-9][0-9]|100)
            # High volume (60-100%)
            icon="$MIC_HIGH"
            color="$PRIMARY_CYAN"
            ;;
        [1-9]|[1-5][0-9])
            # Low volume (1-59%)
            icon="$MIC_LOW"
            color="$PINK"
            ;;
        *)
            # Muted (0%)
            icon="$MIC_MUTED"
            color="$RED"
            ;;
    esac

    # Use our unified animation system
    apply_smooth_animation "$NAME" 30 icon="$icon" icon.color="$color"
}

# --- Label Update ---------------------------------------------------------
update_label() {
    local volume
    volume=$(get_mic_volume)

    if [ "$volume" != "0" ]; then
        # Store current volume in label for restoration after unmute
        apply_instant_change "$NAME" label="$volume" label.drawing=off
    fi
}

# --- Mute Control ---------------------------------------------------------
mute_mic() {
    osascript -e 'set volume input volume 0' 2>/dev/null || true
}

# --- Unmute Control -------------------------------------------------------
unmute_mic() {
    local stored_volume
    # Get stored volume from label
    stored_volume=$(get_item_state "$NAME" "label.value")

    if [ -n "$stored_volume" ] && [ "$stored_volume" != "0" ]; then
        osascript -e "set volume input volume $stored_volume" 2>/dev/null || true
    else
        # Default to 50% if no stored volume
        osascript -e 'set volume input volume 50' 2>/dev/null || true
    fi
}

# --- Toggle Control -------------------------------------------------------
toggle_mic() {
    local current_volume
    current_volume=$(get_mic_volume)

    if [ "$current_volume" = "0" ]; then
        # Currently muted - unmute and restore
        unmute_mic
    else
        # Currently active - store volume and mute
        update_label
        mute_mic
    fi
}

# --- Click Handler --------------------------------------------------------
handle_click() {
    handle_mouse_event "$NAME" "$SENDER"

    # Toggle mic state
    toggle_mic

    # Update visual state
    update_icon
}

# --- Event Handler --------------------------------------------------------
case "$SENDER" in
    "mouse.clicked")
        handle_click
        ;;
    "mouse.entered"|"mouse.exited")
        # Use unified visual feedback system
        handle_mouse_event "$NAME" "$SENDER"
        ;;
    *)
        # Default: Update label and icon
        update_label
        update_icon
        ;;
esac
