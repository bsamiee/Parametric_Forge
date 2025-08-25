#!/usr/bin/env bash
# Title         : dock-setup.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : configs/darwin/scripts/dock-setup.sh
# ----------------------------------------------------------------------------
# macOS Dock configuration script for development-focused setup

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if dockutil is available
if ! command -v dockutil >/dev/null 2>&1; then
    log_error "dockutil is not installed. Please install it first:"
    log_info "brew install dockutil"
    exit 1
fi

log_info "Starting Dock configuration..."

# Remove all existing items from the Dock
log_info "Removing all existing Dock items..."
dockutil --remove all --no-restart 2>/dev/null || log_warning "Some items could not be removed"

# Essential applications (in order of appearance)
declare -a ESSENTIAL_APPS=(
    "/Applications/Safari.app"
    "/Applications/Visual Studio Code.app"
    "/Applications/WezTerm.app"
    "/Applications/1Password 7 - Password Manager.app"
)

# Development applications
declare -a DEV_APPS=(
    "/Applications/Docker Desktop.app"
    "/Applications/Postman.app"
    "/Applications/TablePlus.app"
    "/Applications/Proxyman.app"
)

# Utility applications
declare -a UTILITY_APPS=(
    "/Applications/The Unarchiver.app"
    "/Applications/CleanMyMac X.app"
    "/Applications/Activity Monitor.app"
    "/System/Applications/System Preferences.app"
)

# Function to add application to dock if it exists
add_app_if_exists() {
    local app_path="$1"
    local app_name=$(basename "$app_path" .app)
    
    if [[ -d "$app_path" ]]; then
        log_info "Adding $app_name to Dock..."
        dockutil --add "$app_path" --no-restart 2>/dev/null || log_warning "Could not add $app_name"
    else
        log_warning "$app_name not found at $app_path"
    fi
}

# Add essential applications
log_info "Adding essential applications..."
for app in "${ESSENTIAL_APPS[@]}"; do
    add_app_if_exists "$app"
done

# Add a spacer after essential apps
log_info "Adding spacer..."
dockutil --add '' --type spacer --section apps --no-restart 2>/dev/null || true

# Add development applications
log_info "Adding development applications..."
for app in "${DEV_APPS[@]}"; do
    add_app_if_exists "$app"
done

# Add another spacer
log_info "Adding spacer..."
dockutil --add '' --type spacer --section apps --no-restart 2>/dev/null || true

# Add utility applications
log_info "Adding utility applications..."
for app in "${UTILITY_APPS[@]}"; do
    add_app_if_exists "$app"
done

# Add frequently used folders to the right side of the dock
log_info "Adding folders to Dock..."

# Downloads folder
if [[ -d "$HOME/Downloads" ]]; then
    dockutil --add "$HOME/Downloads" --view fan --display folder --sort name --no-restart 2>/dev/null || log_warning "Could not add Downloads folder"
fi

# Applications folder
if [[ -d "/Applications" ]]; then
    dockutil --add "/Applications" --view grid --display folder --sort name --no-restart 2>/dev/null || log_warning "Could not add Applications folder"
fi

# Development folder (if it exists)
if [[ -d "$HOME/Development" ]]; then
    dockutil --add "$HOME/Development" --view list --display folder --sort name --no-restart 2>/dev/null || log_warning "Could not add Development folder"
elif [[ -d "$HOME/Projects" ]]; then
    dockutil --add "$HOME/Projects" --view list --display folder --sort name --no-restart 2>/dev/null || log_warning "Could not add Projects folder"
elif [[ -d "$HOME/Code" ]]; then
    dockutil --add "$HOME/Code" --view list --display folder --sort name --no-restart 2>/dev/null || log_warning "Could not add Code folder"
fi

# Configure Dock preferences
log_info "Configuring Dock preferences..."

# Set Dock size
defaults write com.apple.dock tilesize -int 48

# Set Dock magnification
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 64

# Set Dock position (bottom, left, right)
defaults write com.apple.dock orientation -string "bottom"

# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0.2
defaults write com.apple.dock autohide-time-modifier -float 0.5

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Minimize windows using scale effect
defaults write com.apple.dock mineffect -string "scale"

# Don't animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool false

# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true

# Don't show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool false

# Group windows by application in Mission Control
defaults write com.apple.dock expose-group-by-app -bool true

# Restart the Dock to apply all changes
log_info "Restarting Dock to apply changes..."
killall Dock

log_success "Dock configuration completed successfully!"

# Show final dock contents
log_info "Current Dock contents:"
dockutil --list 2>/dev/null || log_warning "Could not list Dock contents"

# Provide instructions for manual customization
cat << EOF

${BLUE}Dock Configuration Complete!${NC}

Your Dock has been configured with a development-focused layout:
- Essential apps (Safari, VS Code, WezTerm, 1Password)
- Development tools (Docker, Postman, etc.)
- System utilities

${YELLOW}Manual Customization:${NC}
- Drag apps to reorder them
- Right-click apps for options
- Add more apps by dragging from Applications folder
- Remove apps by dragging them out of the Dock

${YELLOW}Useful Commands:${NC}
- Reset Dock: dockutil --remove all && defaults delete com.apple.dock && killall Dock
- List Dock items: dockutil --list
- Add app: dockutil --add "/Applications/AppName.app"
- Remove app: dockutil --remove "AppName"

EOF