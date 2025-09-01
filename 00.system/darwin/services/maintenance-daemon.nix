# Title         : 00.system/darwin/services/maintenance-daemon.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/services/maintenance-daemon.nix
# ----------------------------------------------------------------------------
# System maintenance daemon for Nix store health and Homebrew cleanup.

{ pkgs, myLib, ... }:

let
  # --- Service Helper Functions ----------------------------------------------
  inherit (myLib.launchd) mkLaunchdDaemon;

  # --- Maintenance Script ---------------------------------------------------
  maintenanceScript = myLib.launchd.mkNamedExecutable pkgs "sys-maintenance-daemon" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    echo "═══════════════════════════════════════════════════════════════════════"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting system maintenance"
    echo "═══════════════════════════════════════════════════════════════════════"

    # --- Store Statistics ---------------------------------------------------
    echo "→ Store statistics:"
    STORE_SIZE=$(du -sh /nix/store 2>/dev/null | cut -f1 || echo "unknown")
    STORE_PATHS=$(find /nix/store -maxdepth 1 -type d 2>/dev/null | wc -l || echo "0")
    GC_ROOTS=$(find /nix/var/nix/gcroots -type l 2>/dev/null | wc -l || echo "0")

    echo "  Store size: $STORE_SIZE"
    echo "  Store paths: $STORE_PATHS"
    echo "  GC roots: $GC_ROOTS"

    # --- Nix Health Checks --------------------------------------------------
    echo "→ Nix health checks:"

    if ${pkgs.nix}/bin/nix store verify --all --no-contents 2>/dev/null; then
      echo "  [OK] Store integrity verified"
    else
      echo "  [WARN] Store verification found issues"
    fi

    if pgrep -x "nix-daemon" > /dev/null; then
      echo "  [OK] Nix daemon is running"
    else
      echo "  [WARN] Nix daemon is not running"
    fi

    # --- Homebrew Maintenance -----------------------------------------------
    if command -v brew >/dev/null 2>&1; then
      echo "→ Homebrew maintenance:"

      if brew cleanup --prune=30 2>/dev/null; then
        echo "  [OK] Cleaned up old Homebrew versions"
      else
        echo "  [WARN] Homebrew cleanup encountered issues"
      fi

      if brew doctor 2>/dev/null | head -10; then
        echo "  [OK] Homebrew doctor check completed"
      else
        echo "  [WARN] Homebrew doctor found issues"
      fi
    else
      echo "  → Homebrew not installed, skipping"
    fi

    # --- Mac App Store Updates ----------------------------------------------
    if command -v mas >/dev/null 2>&1; then
      echo "→ Mac App Store updates:"

      if mas upgrade 2>/dev/null; then
        echo "  [OK] Updated all Mac App Store applications"
      else
        echo "  [WARN] Some App Store updates failed or no updates available"
      fi
    else
      echo "  → mas CLI not installed, skipping App Store updates"
    fi

    # --- Log Rotation -------------------------------------------------------
    echo "→ Log rotation:"
    find /var/log -name "*.log" -mtime +60 -delete 2>/dev/null || true
    echo "  [OK] Rotated old system logs"

    echo "═══════════════════════════════════════════════════════════════════════"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] System maintenance completed"
    echo ""
  '';
in
{
  # --- System Maintenance Daemon --------------------------------------------
  launchd.daemons.nix-store-maintenance = mkLaunchdDaemon pkgs {
    command = "${maintenanceScript}/bin/sys-maintenance-daemon";
    label = "Sys Maintenance Daemon";
    startCalendarInterval = [
      {
        Hour = 3;
        Minute = 0;
      }
    ];
    nice = 19;
    logBaseName = "/var/log/system-maintenance";
    ExitTimeOut = 3600;
    LowPriorityIO = true;
    ProcessType = "Background";
  };
}
