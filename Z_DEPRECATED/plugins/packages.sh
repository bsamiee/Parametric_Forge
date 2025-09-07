#!/bin/bash
# Title         : packages.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/packages.sh
# ----------------------------------------------------------------------------
# Cross-platform package manager counter with caching (Homebrew, Nix, npm, uv, cargo)
# shellcheck disable=SC1091
# shellcheck disable=SC2126 # Complex pipeline needs grep+wc, not grep -c

# --- Configuration --------------------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Nix Counter ----------------------------------------------------------
count_nix_packages() {
    local profile="$1"

    if [[ ! -d "$profile" ]]; then
        echo "0"
        return
    fi

    # Query Nix store for package count
    nix-store --query --requisites "$profile" 2>/dev/null | \
        grep -E '([0-9]{1,}\.)+[0-9]{1,}' | \
        grep -v -E '\-doc$|\-man$|\-info$|\-dev$|\-bin$|^nixos-system-nixos-' | \
        wc -l 2>/dev/null || echo "0"
}

# --- Directory Counter ----------------------------------------------------
count_directory_packages() {
    local directory="$1"

    if [[ -d "$directory" ]]; then
        find "$directory" -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# --- Total Calculator -----------------------------------------------------
calculate_total_packages() {
    local total=0
    local count

    # Nix package managers
    for profile in "/nix/var/nix/profiles/default" "/run/current-system" "$HOME/.nix-profile"; do
        count=$(count_nix_packages "$profile")
        total=$((total + count))
    done

    # Homebrew package managers
    for directory in "/opt/homebrew/Caskroom" "/opt/homebrew/Cellar" "$HOME/local/Caskroom" "$HOME/local/Cellar"; do
        count=$(count_directory_packages "$directory")
        total=$((total + count))
    done

    echo "$total"
}

# --- Display Update -------------------------------------------------------
update_packages() {
    local total_packages
    total_packages=$(calculate_total_packages)

    # Update label with total count
    apply_instant_change "$NAME" label="$total_packages"
}

# --- Event Handler --------------------------------------------------------
case "$SENDER" in
    "mouse.entered"|"mouse.exited")
        # Use unified visual feedback system
        handle_mouse_event "$NAME" "$SENDER"
        ;;
    *)
        # Default: Update package count
        update_packages
        ;;
esac
