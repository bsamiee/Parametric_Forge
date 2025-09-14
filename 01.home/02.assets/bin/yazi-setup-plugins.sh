#!/usr/bin/env bash
# Title         : yazi-setup-plugins.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/02.assets/bin/yazi-setup-plugins.sh
# ----------------------------------------------------------------------------
# Yazi plugin management - idempotent installation using ya pkg

set -euo pipefail

# --- Configuration ----------------------------------------------------------
readonly SCRIPT_NAME
SCRIPT_NAME="$(basename "$0")"
readonly YAZI_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yazi"
readonly PACKAGE_FILE="$YAZI_CONFIG_DIR/package.toml"

# --- Logging ----------------------------------------------------------------
log() {
    echo "[$SCRIPT_NAME] $*"
}

error() {
    echo "[$SCRIPT_NAME] ERROR: $*" >&2
}

# --- Prerequisite Checks ---------------------------------------------------
check_prerequisites() {
    if ! command -v ya >/dev/null 2>&1; then
        error "Yazi CLI 'ya' not found in PATH"
        error "Install yazi package or ensure it's in PATH"
        return 1
    fi

    if ! command -v yazi >/dev/null 2>&1; then
        error "Yazi 'yazi' not found in PATH"
        error "Install yazi package or ensure it's in PATH"
        return 1
    fi

    # Ensure config directory exists
    mkdir -p "$YAZI_CONFIG_DIR"
}

# --- Plugin Definitions -----------------------------------------------------
# Define all desired plugins in arrays for easy maintenance
declare -ra CORE_PLUGINS=(
    "yazi-rs/plugins:session"           # Session management
    "Rolv-Apneseth/starship.yazi"       # Starship integration
    "orhnk/system-clipboard"            # System clipboard
    "yazi-rs/plugins:smart-paste"       # Smart paste operations
    "boydaihungst/restore"              # File recovery from trash
    "Mr-Ples/command-palette"           # Fuzzy command palette
    "yazi-rs/plugins:mactag"            # macOS tagging integration
)

declare -ra NAVIGATION_PLUGINS=(
    "yazi-rs/plugins:smart-enter"       # Smart directory entry
    "Rolv-Apneseth/bypass"              # Skip single subdirectories
    "dedukun/relative-motions"          # Vim-style numbered motions
    "yazi-rs/plugins:jump-to-char"      # Character jumping
    "mikavilpas/easyjump"               # Visual jumping
    "yazi-rs/plugins:smart-filter"      # Continuous filtering
    "WhoSowSee/whoosh"                  # Advanced bookmark manager
    "bulletmark/cdhist"                 # Directory history navigation
)

declare -ra UI_PLUGINS=(
    "yazi-rs/plugins:toggle-pane"       # Pane management
    "MasouShizuka/projects"             # Project sessions
    "MasouShizuka/close-and-restore-tab" # Tab recovery
    "boydaihungst/pref-by-location"     # Location preferences
    "dawsers/dual-pane"                 # Dual pane navigation
    "uhs-robert/recycle-bin"            # Enhanced trash management
)

declare -ra DEV_PLUGINS=(
    "yazi-rs/plugins:git"               # Git integration
    "yazi-rs/plugins:vcs-files"         # VCS file status
    "KKV9/compress"                     # Archive creation
    "yazi-rs/plugins:lsar"              # Archive preview
    "yazi-rs/plugins:chmod"             # Permission management
    "yazi-rs/plugins:diff"              # File comparison
    "yazi-rs/plugins:mime-ext"          # MIME detection
    "AnirudhG07/custom-shell"           # Shell integration
    "yazi-rs/plugins:mount"             # Device mounting
    "yazi-rs/plugins:piper"             # Command previews
)

declare -ra MEDIA_PLUGINS=(
    "AnirudhG07/nbpreview"              # Jupyter notebooks
    "AnirudhG07/rich-preview"           # Rich document preview
    "navysky12/comicthumb"              # Comic book archives
    "yazi-rs/plugins:zoom"              # Image zoom
    "boydaihungst/mediainfo"            # Media metadata
    "Sonico98/exifaudio"                # Audio metadata
    "vmikk/zless-preview"               # Compressed text
    "wylie102/duckdb"                   # SQL data preview
    "Reledia/hexyl"                     # Binary/hex viewer
)

# --- Plugin Management Functions -------------------------------------------
get_installed_plugins() {
    if [[ ! -f "$PACKAGE_FILE" ]]; then
        return 0
    fi

    # Extract plugin names from package.toml
    grep -E '^\s*use\s*=' "$PACKAGE_FILE" 2>/dev/null | \
        sed 's/.*use\s*=\s*"\([^"]*\)".*/\1/' || true
}

is_plugin_installed() {
    local plugin="$1"
    local installed
    installed=$(get_installed_plugins)

    # Check if plugin is in installed list
    echo "$installed" | grep -Fxq "$plugin"
}

install_plugin() {
    local plugin="$1"

    if is_plugin_installed "$plugin"; then
        log "✓ Plugin already installed: $plugin"
        return 0
    fi

    log "Installing plugin: $plugin"
    if ya pkg add "$plugin" 2>/dev/null; then
        log "✓ Successfully installed: $plugin"
    else
        error "Failed to install: $plugin"
        return 1
    fi
}

install_plugin_group() {
    local group_name="$1"
    shift
    local plugins=("$@")

    log "Installing $group_name plugins..."

    local failed=0
    for plugin in "${plugins[@]}"; do
        if ! install_plugin "$plugin"; then
            ((failed++))
        fi
    done

    if ((failed > 0)); then
        error "$failed plugin(s) failed to install in $group_name"
        return 1
    fi

    log "✓ All $group_name plugins installed"
}

# --- Main Installation Logic -----------------------------------------------
install_all_plugins() {
    log "Starting Yazi plugin installation..."

    local total_failed=0

    # Install each plugin group
    install_plugin_group "core" "${CORE_PLUGINS[@]}" || ((total_failed++))
    install_plugin_group "navigation" "${NAVIGATION_PLUGINS[@]}" || ((total_failed++))
    install_plugin_group "UI" "${UI_PLUGINS[@]}" || ((total_failed++))
    install_plugin_group "development" "${DEV_PLUGINS[@]}" || ((total_failed++))
    install_plugin_group "media" "${MEDIA_PLUGINS[@]}" || ((total_failed++))

    if ((total_failed > 0)); then
        error "Some plugin groups failed to install completely"
        return 1
    fi

    log "✅ All plugin groups installed successfully"
}

# --- Status and Information Functions ---------------------------------------
show_status() {
    log "Yazi Plugin Status"
    log "=================="
    log "Package file: $PACKAGE_FILE"

    if [[ -f "$PACKAGE_FILE" ]]; then
        local count
        count=$(get_installed_plugins | wc -l | tr -d ' ')
        log "Installed plugins: $count"
        log ""
        log "Plugin list:"
        get_installed_plugins | sort | sed 's/^/  - /'
    else
        log "No plugins installed yet"
    fi
}

show_help() {
    cat <<EOF
$SCRIPT_NAME - Yazi Plugin Manager

USAGE:
    $SCRIPT_NAME [COMMAND]

COMMANDS:
    install     Install/update all defined plugins (default)
    status      Show current plugin installation status
    list        List all defined plugins
    help        Show this help message

FEATURES:
    • Idempotent: Only installs missing plugins
    • Uses proper 'ya pkg' commands for correct package.toml format
    • Groups plugins logically for better organization
    • Provides detailed status and error reporting

CONFIGURATION:
    Package file: $PACKAGE_FILE

The script automatically generates the correct package.toml format using
ya pkg commands, ensuring compatibility with Yazi's plugin system.

EOF
}

list_defined_plugins() {
    log "Defined Plugins"
    log "==============="

    echo "Core Plugins:"
    printf "  %s\n" "${CORE_PLUGINS[@]}"

    echo "Navigation Plugins:"
    printf "  %s\n" "${NAVIGATION_PLUGINS[@]}"

    echo "UI Plugins:"
    printf "  %s\n" "${UI_PLUGINS[@]}"

    echo "Development Plugins:"
    printf "  %s\n" "${DEV_PLUGINS[@]}"

    echo "Media Plugins:"
    printf "  %s\n" "${MEDIA_PLUGINS[@]}"

    local total=$((${#CORE_PLUGINS[@]} + ${#NAVIGATION_PLUGINS[@]} + ${#UI_PLUGINS[@]} + ${#DEV_PLUGINS[@]} + ${#MEDIA_PLUGINS[@]}))
    echo ""
    echo "Total: $total plugins"
}

# --- Main Function ---------------------------------------------------------
main() {
    local command="${1:-install}"

    case "$command" in
        install)
            check_prerequisites
            install_all_plugins
            ;;
        status)
            check_prerequisites
            show_status
            ;;
        list)
            list_defined_plugins
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# --- Entry Point -----------------------------------------------------------
main "$@"