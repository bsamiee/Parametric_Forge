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

    # --- Helper Functions ----------------------------------------------------
    check_command() { command -v "$1" >/dev/null 2>&1; }

    log_status() { echo "  [$1] $2"; }

    indent_output() {
      while IFS= read -r line; do
        echo "    $line"
      done
    }

    # --- Header --------------------------------------------------------------
    echo "═══════════════════════════════════════════════════════════════════════"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting system maintenance"
    echo "═══════════════════════════════════════════════════════════════════════"

    # --- Command Line Tools Health Check ------------------------------------
    echo "→ Command Line Tools health:"

    if CLT_PATH=$(xcode-select -p 2>/dev/null) && [[ -d "$CLT_PATH" ]]; then
      log_status "OK" "CLT installed: $CLT_PATH"

      if CLT_VER=$(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | awk '/version/ {print $2}'); then
        log_status "OK" "Version: $CLT_VER"
      else
        log_status "WARN" "Package corrupted"
      fi

      MISSING_TOOLS=()
      for tool in clang git make ld; do
        check_command "$tool" || MISSING_TOOLS+=("$tool")
      done

      if [[ ''${#MISSING_TOOLS[@]} -eq 0 ]]; then
        log_status "OK" "Core tools available"
      else
        log_status "WARN" "Missing tools: ''${MISSING_TOOLS[*]}"
      fi

      TEMP_FILE=$(mktemp)
      if echo 'int main(){return 0;}' | clang -x c - -o "$TEMP_FILE" 2>/dev/null && "$TEMP_FILE"; then
        log_status "OK" "Compilation working"
        rm -f "$TEMP_FILE"
      else
        log_status "WARN" "Compilation failed"
        rm -f "$TEMP_FILE"
      fi
    else
      log_status "ERROR" "CLT not installed"
    fi

    if UPDATES=$(softwareupdate -l 2>/dev/null | grep -i "command line tools\|developer"); then
      log_status "WARN" "Updates available"
      echo "$UPDATES" | indent_output
    else
      log_status "OK" "No CLT updates"
    fi

    if check_command brew; then
      if CLT_STATUS=$(brew config 2>/dev/null | grep "CLT:"); then
        log_status "OK" "Homebrew: $CLT_STATUS"
      else
        log_status "WARN" "Homebrew CLT status unknown"
      fi
    fi

    # --- Store Statistics ---------------------------------------------------
    echo "→ Store statistics:"

    STORE_SIZE=$(du -sh /nix/store 2>/dev/null | cut -f1 || echo "unknown")
    STORE_PATHS=$(find /nix/store -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    GC_ROOTS=$(find /nix/var/nix/gcroots -type l 2>/dev/null | wc -l | tr -d ' ' || echo "0")

    echo "  Store size: $STORE_SIZE"
    echo "  Store paths: $STORE_PATHS"
    echo "  GC roots: $GC_ROOTS"

    # --- Nix Health Checks --------------------------------------------------
    echo "→ Nix health checks:"

    if nix store verify --all --no-contents 2>/dev/null; then
      log_status "OK" "Store integrity verified"
    else
      log_status "WARN" "Store verification found issues"
    fi

    if pgrep -x "nix-daemon" >/dev/null; then
      log_status "OK" "Nix daemon running"
    else
      log_status "WARN" "Nix daemon not running"
    fi

    # --- Homebrew Maintenance -----------------------------------------------
    if check_command brew; then
      echo "→ Homebrew maintenance:"

      if brew cleanup --prune=30 >/dev/null 2>&1; then
        log_status "OK" "Cleaned old Homebrew versions"
      else
        log_status "WARN" "Homebrew cleanup failed"
      fi

      if DOCTOR_OUTPUT=$(brew doctor 2>&1); then
        if echo "$DOCTOR_OUTPUT" | grep -q "Your system is ready to brew"; then
          log_status "OK" "Homebrew health check passed"
        else
          log_status "WARN" "Homebrew doctor found issues"
          echo "$DOCTOR_OUTPUT" | head -5 | indent_output
        fi
      else
        log_status "WARN" "Homebrew doctor check failed"
      fi
    else
      echo "  → Homebrew not installed, skipping"
    fi

    # --- Mac App Store Updates ----------------------------------------------
    if check_command mas; then
      echo "→ Mac App Store updates:"

      if MAS_OUTPUT=$(mas upgrade 2>&1); then
        if echo "$MAS_OUTPUT" | grep -q "Everything up-to-date"; then
          log_status "OK" "All Mac App Store apps up-to-date"
        else
          log_status "OK" "Mac App Store apps updated"
          echo "$MAS_OUTPUT" | indent_output
        fi
      else
        log_status "WARN" "Mac App Store update failed"
      fi
    else
      echo "  → mas CLI not installed, skipping App Store updates"
    fi

    # --- Log Rotation -------------------------------------------------------
    echo "→ Log rotation:"

    LOG_COUNT=$(find /var/log -name "*.log" -mtime +60 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$LOG_COUNT" -gt 0 ]]; then
      find /var/log -name "*.log" -mtime +60 -delete 2>/dev/null || true
      log_status "OK" "Rotated $LOG_COUNT old system logs"
    else
      log_status "OK" "No old logs to rotate"
    fi

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
