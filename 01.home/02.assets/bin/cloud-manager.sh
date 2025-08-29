#!/bin/bash
# Title         : cloud-manager.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/02.assets/bin/cloud-manager.sh
# ----------------------------------------------------------------------------
# Manage multiple cloud storage services and File Provider performance

set -euo pipefail

show_usage() {
    cat << EOF
Cloud Storage Manager

USAGE:
    cloud-manager.sh <command>

COMMANDS:
    status      Show current cloud service resource usage
    restart     Restart all cloud services cleanly
    pause       Pause resource-intensive services
    resume      Resume paused services
    spotlight   Add/remove cloud folders from Spotlight indexing
    cleanup     Clean File Provider cache and restart services

EXAMPLES:
    cloud-manager.sh status
    cloud-manager.sh restart
    cloud-manager.sh spotlight exclude
EOF
}

show_status() {
    echo "=== Cloud Services Status ==="
    echo
    echo "File Provider Daemon:"
    ps aux | grep -E "fileproviderd" | grep -v grep || echo "Not running"
    echo
    echo "Google Drive Processes:"
    ps aux | grep -E "Google Drive" | grep -v grep | wc -l | xargs echo "Count:"
    echo
    echo "MEGAsync Processes:"
    ps aux | grep -E "MEGAsync" | grep -v grep | wc -l | xargs echo "Count:"
    echo
    echo "Cloud Storage Mounts:"
    ls -la "/Users/$(whoami)/Library/CloudStorage/" | grep -E "^d" | wc -l | xargs echo "Active mounts:"
    echo
    echo "Top CPU Consumers:"
    ps aux | grep -E "(fileproviderd|Google Drive|MEGAsync|OneDrive)" | grep -v grep | sort -k3 -nr | head -5
}

restart_services() {
    echo "=== Restarting Cloud Services ==="
    
    # Gracefully quit applications
    osascript -e 'quit app "Google Drive"' 2>/dev/null || true
    osascript -e 'quit app "MEGAsync"' 2>/dev/null || true
    osascript -e 'quit app "Microsoft OneDrive"' 2>/dev/null || true
    
    sleep 3
    
    # Force kill if still running
    pkill -f "Google Drive" 2>/dev/null || true
    pkill -f "MEGAsync" 2>/dev/null || true
    pkill -f "OneDrive" 2>/dev/null || true
    
    sleep 2
    
    # Restart File Provider daemon
    sudo pkill -f fileproviderd 2>/dev/null || true
    
    echo "Services stopped. Restart them manually from Applications folder."
    echo "This allows them to reinitialize cleanly."
}

manage_spotlight() {
    local action="${1:-}"
    
    case "$action" in
        exclude)
            echo "Adding cloud storage folders to Spotlight privacy..."
            echo "Opening System Settings > Spotlight > Privacy"
            echo "Manually add these folders:"
            ls -d "/Users/$(whoami)/Library/CloudStorage"/* 2>/dev/null || true
            open "x-apple.systempreferences:com.apple.preference.spotlight?Privacy"
            ;;
        include)
            echo "To include folders back in Spotlight:"
            echo "System Settings > Spotlight > Privacy"
            echo "Remove cloud storage folders from the list"
            open "x-apple.systempreferences:com.apple.preference.spotlight?Privacy"
            ;;
        *)
            echo "Usage: cloud-manager.sh spotlight [exclude|include]"
            ;;
    esac
}

cleanup_cache() {
    echo "=== Cleaning File Provider Cache ==="
    
    # Stop services first
    restart_services
    sleep 5
    
    # Clean Google Drive cache
    rm -rf "/Users/$(whoami)/Library/Application Support/Google/DriveFS/cef_cache" 2>/dev/null || true
    rm -rf "/Users/$(whoami)/Library/Caches/com.google.drivefs" 2>/dev/null || true
    
    # Clean MEGAsync cache
    rm -rf "/Users/$(whoami)/Library/Caches/Mega Limited" 2>/dev/null || true
    
    # Clean OneDrive cache
    rm -rf "/Users/$(whoami)/Library/Caches/com.microsoft.OneDrive" 2>/dev/null || true
    
    echo "Cache cleared. Restart your cloud services."
}

pause_services() {
    echo "=== Pausing Resource-Intensive Services ==="
    osascript -e 'quit app "MEGAsync"' 2>/dev/null || true
    # Keep Google Drive and OneDrive for essential sync
    echo "MEGAsync paused. Google Drive and OneDrive remain active."
}

resume_services() {
    echo "=== Resuming All Services ==="
    open -a "MEGAsync" 2>/dev/null || true
    echo "All services resumed."
}

# Main command dispatcher
case "${1:-}" in
    status) show_status ;;
    restart) restart_services ;;
    pause) pause_services ;;
    resume) resume_services ;;
    spotlight) manage_spotlight "${2:-}" ;;
    cleanup) cleanup_cache ;;
    *) show_usage ;;
esac