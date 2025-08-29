# Title         : clt-daemon.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/services/clt-daemon.nix
# ----------------------------------------------------------------------------
# Command Line Tools health monitoring daemon.

{ pkgs, myLib, ... }:

let
  cltScript = pkgs.writeShellScript "clt-monitor" ''
    set -euo pipefail

    log() { echo "[$(date '+%H:%M:%S')] $1"; }
    check() { command -v "$1" >/dev/null 2>&1; }

    log "CLT Health Check"

    # Core status
    if CLT_PATH=$(xcode-select -p 2>/dev/null) && [[ -d "$CLT_PATH" ]]; then
      log "[OK] CLT installed: $CLT_PATH"

      # Version check
      if CLT_VER=$(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | awk '/version/ {print $2}'); then
        log "[OK] Version: $CLT_VER"
      else
        log "[WARN] Package corrupted"
      fi

      # Tool availability
      MISSING=""
      for tool in clang git make ld; do
        check "$tool" || MISSING="$MISSING $tool"
      done
      [[ -z "$MISSING" ]] && log "[OK] Core tools available" || log "[WARN] Missing:$MISSING"

      # Compilation test
      if echo 'int main(){return 0;}' | clang -x c - -o /tmp/clt_test 2>/dev/null && /tmp/clt_test; then
        log "[OK] Compilation working"
        rm -f /tmp/clt_test
      else
        log "[WARN] Compilation failed"
      fi
    else
      log "[ERROR] CLT not installed"
    fi

    # Update check
    if UPDATES=$(softwareupdate -l 2>/dev/null | grep -i "command line tools\|developer"); then
      log "[WARN] Updates available"
      echo "$UPDATES"
    else
      log "[OK] No CLT updates"
    fi

    # Homebrew compatibility
    if check brew && CLT_STATUS=$(brew config 2>/dev/null | grep "CLT:"); then
      log "[OK] Homebrew: $CLT_STATUS"
    elif check brew; then
      log "[WARN] Homebrew CLT status unknown"
    fi
  '';
in
{
  launchd.daemons.xcode-clt-monitor = myLib.launchd.mkLaunchdDaemon pkgs {
    command = "${cltScript}";
    label = "X-Tools Daemon";
    startCalendarInterval = [
      {
        Hour = 6;
        Minute = 0;
      }
    ];
    nice = 15;
    logBaseName = "/var/log/clt-monitor";
    ExitTimeOut = 180;
    ProcessType = "Background";
  };
}
