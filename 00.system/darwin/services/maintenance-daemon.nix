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

    # --- Command Line Tools Health Check ------------------------------------
    echo "→ Command Line Tools health:"

    check() { command -v "$1" >/dev/null 2>&1; }

    if CLT_PATH=$(xcode-select -p 2>/dev/null) && [[ -d "$CLT_PATH" ]]; then
      echo "  [OK] CLT installed: $CLT_PATH"

      # Version check
      if CLT_VER=$(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | awk '/version/ {print $2}'); then
        echo "  [OK] Version: $CLT_VER"
      else
        echo "  [WARN] Package corrupted"
      fi

      # Tool availability
      MISSING=""
      for tool in clang git make ld; do
        check "$tool" || MISSING="$MISSING $tool"
      done
      if [[ -z "$MISSING" ]]; then
        echo "  [OK] Core tools available"
      else
        echo "  [WARN] Missing:$MISSING"
      fi

      # Compilation test
      if echo 'int main(){return 0;}' | clang -x c - -o /tmp/clt_test 2>/dev/null && /tmp/clt_test; then
        echo "  [OK] Compilation working"
        rm -f /tmp/clt_test
      else
        echo "  [WARN] Compilation failed"
      fi
    else
      echo "  [ERROR] CLT not installed"
    fi

    # Update check
    if UPDATES=$(softwareupdate -l 2>/dev/null | grep -i "command line tools\|developer"); then
      echo "  [WARN] Updates available"
      echo "${UPDATES//$'\n'/$'\n'    }"
    else
      echo "  [OK] No CLT updates"
    fi

    # Homebrew compatibility
    if check brew && CLT_STATUS=$(brew config 2>/dev/null | grep "CLT:"); then
      echo "  [OK] Homebrew: $CLT_STATUS"
    elif check brew; then
      echo "  [WARN] Homebrew CLT status unknown"
    fi

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
