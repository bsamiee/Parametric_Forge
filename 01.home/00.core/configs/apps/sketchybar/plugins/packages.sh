#!/bin/bash
# Title         : packages.sh
# Author        : Bardia Samiee (adapted from reference)
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/packages.sh
# ----------------------------------------------------------------------------
# Multi-manager package counter with caching
# shellcheck disable=SC1091
# shellcheck disable=SC2126 # Complex pipeline needs grep+wc, not grep -c

# --- Load Configuration Variables -------------------------------------------
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/constants.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/helpers/interaction-helpers.sh"

# --- Count Nix Packages -----------------------------------------------------
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

# --- Count Directory Packages -----------------------------------------------
count_directory_packages() {
    local directory="$1"

    if [[ -d "$directory" ]]; then
        find "$directory" -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# --- Calculate Total Package Count ------------------------------------------
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

# --- Update Package Display -------------------------------------------------
update_packages() {
    local total_packages
    total_packages=$(calculate_total_packages)

    # Update label with total count
    apply_instant_change "$NAME" label="$total_packages"
}

# --- Main Event Handler -----------------------------------------------------
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
