# Title         : 00.system/darwin/settings/security.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/settings/security.nix
# ----------------------------------------------------------------------------
# Security, PAM, certificates, and firewall configuration for Darwin.

{ lib, ... }:

let
  inherit (lib) mkDefault;
in
{
  # --- Security Configuration -----------------------------------------------
  security = {
    # --- PAM Authentication -------------------------------------------------
    pam.services.sudo_local = {
      enable = mkDefault true;
      touchIdAuth = mkDefault true;
      watchIdAuth = mkDefault false;
      reattach = mkDefault false;
    };
    # --- Certificate Management ---------------------------------------------
    pki = {
      installCACerts = mkDefault true;
      certificateFiles = [ ];
      certificates = [ ];
      caCertificateBlacklist = [ ];
    };
    # --- Sudoers Configuration -----------------------------------------------
    sudo = {
      extraConfig = ''
        # Allow passwordless system maintenance commands
        %admin ALL=(root) NOPASSWD: /usr/bin/mdutil *
        %admin ALL=(root) NOPASSWD: /usr/bin/tmutil addexclusion *
        %admin ALL=(root) NOPASSWD: /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister *
        %admin ALL=(root) NOPASSWD: /usr/bin/defaults write /Library/Preferences/com.apple.security*
        %admin ALL=(root) NOPASSWD: /usr/sbin/spctl *
        %admin ALL=(root) NOPASSWD: /usr/bin/killall *
        %admin ALL=(root) NOPASSWD: /usr/bin/dscacheutil *
        %admin ALL=(root) NOPASSWD: /usr/sbin/softwareupdate *
        %admin ALL=(root) NOPASSWD: /usr/bin/xcode-select *
        %admin ALL=(root) NOPASSWD: /usr/bin/pkgutil *
        %admin ALL=(root) NOPASSWD: /usr/libexec/ApplicationFirewall/socketfilterfw *
        %admin ALL=(root) NOPASSWD: /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings *

        # Allow TCC database management (requires SIP disabled)
        %admin ALL=(root) NOPASSWD: /usr/bin/sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db *
        %admin ALL=(root) NOPASSWD: /usr/bin/sqlite3 /Users/*/Library/Application\ Support/com.apple.TCC/TCC.db *
        %admin ALL=(root) NOPASSWD: /usr/bin/tccutil *

        # Allow service management for window managers
        %admin ALL=(root) NOPASSWD: /bin/launchctl *
        %admin ALL=(root) NOPASSWD: /usr/bin/osascript *

        # Allow darwin-rebuild without password (match absolute paths)
        # SETENV allows passing NIX_CONFIG for flakes support from HS
        %admin ALL=(root) NOPASSWD,SETENV: /run/current-system/sw/bin/darwin-rebuild *
        %admin ALL=(root) NOPASSWD,SETENV: /nix/var/nix/profiles/default/bin/darwin-rebuild *
        %admin ALL=(root) NOPASSWD,SETENV: /Users/*/.nix-profile/bin/darwin-rebuild *

        # yabai scripting addition (path-restricted, no hash dependency)
        %admin ALL=(root) NOPASSWD: /opt/homebrew/bin/yabai --load-sa

        # Window manager tools (skhd, borders)
        %admin ALL=(root) NOPASSWD: /opt/homebrew/bin/skhd *
        %admin ALL=(root) NOPASSWD: /opt/homebrew/bin/borders *

        # Homebrew shell integration (prevents login security prompts)
        %admin ALL=(root) NOPASSWD: /opt/homebrew/bin/brew *
        %admin ALL=(root) NOPASSWD: /usr/local/bin/brew *

        # Developer tools and services
        %admin ALL=(root) NOPASSWD: /usr/bin/codesign *
        %admin ALL=(root) NOPASSWD: /usr/sbin/chown *
        %admin ALL=(root) NOPASSWD: /bin/chmod *
        %admin ALL=(root) NOPASSWD: /usr/bin/security *
        %admin ALL=(root) NOPASSWD: /usr/bin/plutil *
        %admin ALL=(root) NOPASSWD: /usr/libexec/PlistBuddy *

        # Installation tools (for complex app installations like Parallels)
        %admin ALL=(root) NOPASSWD: /usr/bin/ditto *
        %admin ALL=(root) NOPASSWD: /usr/bin/installer *
        %admin ALL=(root) NOPASSWD: /usr/sbin/installer *

        # Allow environment preservation for installer packages (Adobe, etc.)
        %admin ALL=(root) NOPASSWD,SETENV: /usr/sbin/installer *

        # Allow 1Password CLI operations (no special privileges needed, but for completeness)
        %admin ALL=(root) NOPASSWD: /opt/homebrew/bin/op *
        %admin ALL=(root) NOPASSWD: /usr/local/bin/op *
      '';
    };
  };
  # --- Networking Security (Application Firewall) ---------------------------
  networking.applicationFirewall = {
    enable = mkDefault false;
    blockAllIncoming = mkDefault false;
    allowSigned = mkDefault true;
    allowSignedApp = mkDefault true;
    enableStealthMode = mkDefault false;
  };

  # --- Comprehensive TCC Permission Automation (requires SIP disabled) -----
  system.activationScripts.preActivation.text = ''
    echo "Configuring comprehensive TCC permissions..." >&2

    # Find primary user (first non-system user in /Users)
    PRIMARY_USER=""
    for user in /Users/*; do
      [ -d "$user" ] && [ "$(basename "$user")" != "Shared" ] && PRIMARY_USER="$(basename "$user")" && break
    done
    USER_TCC_DB="/Users/$PRIMARY_USER/Library/Application Support/com.apple.TCC/TCC.db"

    # Enhanced TCC permission function with comprehensive services
    grant_tcc() {
      local db="$1" service="$2" client="$3" type="''${4:-0}" target="''${5:-}"
      [ -f "$db" ] || return

      # Check if permission already exists and is granted
      existing=$(/usr/bin/sqlite3 "$db" "SELECT auth_value FROM access WHERE service='$service' AND client='$client'" 2>/dev/null || echo "")
      [ "$existing" = "2" ] && return  # Already granted

      # Remove any existing entry to avoid conflicts
      /usr/bin/sqlite3 "$db" "DELETE FROM access WHERE service='$service' AND client='$client'" 2>/dev/null || true

      if [ -n "$target" ]; then
        # AppleEvents with target
        /usr/bin/sqlite3 "$db" "INSERT INTO access (service,client,client_type,auth_value,auth_reason,auth_version,indirect_object_identifier,flags,last_modified) VALUES ('$service','$client',$type,2,4,1,'$target',0,strftime('%s','now'))"
      else
        # Standard permission (2 = granted, 1 = denied, 0 = not set)
        /usr/bin/sqlite3 "$db" "INSERT INTO access (service,client,client_type,auth_value,auth_reason,auth_version,flags,last_modified) VALUES ('$service','$client',$type,2,1,1,0,strftime('%s','now'))"
      fi
      echo "  ✓ Granted $service to $client" >&2
    }

    # Comprehensive shell and system permissions
    echo "  Configuring shell and system permissions..." >&2
    for shell in /bin/sh /bin/bash /bin/zsh /usr/bin/osascript; do
      [ -f "$shell" ] || continue
      grant_tcc "$USER_TCC_DB" "kTCCServiceAccessibility" "$shell" 1
      grant_tcc "$USER_TCC_DB" "kTCCServiceSystemPolicyAllFiles" "$shell" 1
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$shell" 1 "com.apple.systemevents"
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$shell" 1 "com.apple.finder"
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$shell" 1 "com.apple.controlcenter"
    done

    # 1Password CLI and Desktop App Integration
    echo "  Configuring 1Password permissions..." >&2
    OP_PATHS=(
      "/opt/homebrew/bin/op"
      "/usr/local/bin/op"
      "/Applications/1Password.app"
    )

    for op_path in "''${OP_PATHS[@]}"; do
      [ -e "$op_path" ] || continue

      if [[ "$op_path" == *.app ]]; then
        # App bundle - use proper bundle identifier for 1Password 8
        client="com.1password.1password"
        type=0
      else
        # CLI binary
        client="$op_path"
        type=1
      fi

      grant_tcc "$USER_TCC_DB" "kTCCServiceAccessibility" "$client" "$type"
      grant_tcc "$USER_TCC_DB" "kTCCServiceSystemPolicyAllFiles" "$client" "$type"
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$client" "$type" "com.apple.systemevents"
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$client" "$type" "com.apple.controlcenter"
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$client" "$type" "com.apple.finder"
    done

    # Daemon services needing comprehensive access
    echo "  Configuring daemon permissions..." >&2
    DAEMONS=(
      "font-cache-daemon"
      "home-maintenance-daemon"
      "npm-daemon"
      "op-ssh-setup"
      "security-daemon"
      "sys-maintenance-daemon"
    )

    for daemon in "''${DAEMONS[@]}"; do
      grant_tcc "$USER_TCC_DB" "kTCCServiceAccessibility" "$daemon" 1
      grant_tcc "$USER_TCC_DB" "kTCCServiceSystemPolicyAllFiles" "$daemon" 1
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$daemon" 1 "com.apple.systemevents"
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$daemon" 1 "com.apple.controlcenter"
    done

    # Window Management Tools - comprehensive permissions
    echo "  Configuring window management permissions..." >&2
    WM_TOOLS=(
      "/opt/homebrew/bin/yabai"
      "/opt/homebrew/bin/skhd"
      "/opt/homebrew/bin/borders"
      "/usr/local/bin/borders"
    )

    for tool in "''${WM_TOOLS[@]}"; do
      [ -f "$tool" ] || continue
      grant_tcc "$USER_TCC_DB" "kTCCServiceAccessibility" "$tool" 1
      grant_tcc "$USER_TCC_DB" "kTCCServicePostEvent" "$tool" 1
      grant_tcc "$USER_TCC_DB" "kTCCServiceListenEvent" "$tool" 1
      grant_tcc "$USER_TCC_DB" "kTCCServiceSystemPolicyAllFiles" "$tool" 1
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$tool" 1 "com.apple.systemevents"
    done

    # Karabiner-Elements - input monitoring & accessibility
    echo "  Configuring Karabiner-Elements permissions..." >&2
    KARABINER_ENTRIES=(
      "/Applications/Karabiner-Elements.app"
      "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_grabber"
      "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_observer"
    )

    for entry in "''${KARABINER_ENTRIES[@]}"; do
      [ -e "$entry" ] || continue
      if [[ "$entry" == *.app ]]; then
        client="org.pqrs.Karabiner-Elements"
        type=0
      else
        client="$entry"
        type=1
      fi
      # Input Monitoring (listen to key events)
      grant_tcc "$USER_TCC_DB" "kTCCServiceListenEvent" "$client" "$type"
      # Accessibility (assistive control)
      grant_tcc "$USER_TCC_DB" "kTCCServiceAccessibility" "$client" "$type"
    done

    # Hammerspoon - automation and window management
    echo "  Configuring Hammerspoon permissions..." >&2
    HAMMERSPOON_PATHS=(
      "/Applications/Hammerspoon.app"
    )

    for hs_path in "''${HAMMERSPOON_PATHS[@]}"; do
      [ -e "$hs_path" ] || continue

      # Use proper bundle identifier for Hammerspoon
      client="org.hammerspoon.Hammerspoon"
      type=0

      grant_tcc "$USER_TCC_DB" "kTCCServiceAccessibility" "$client" "$type"
      grant_tcc "$USER_TCC_DB" "kTCCServicePostEvent" "$client" "$type"
      grant_tcc "$USER_TCC_DB" "kTCCServiceListenEvent" "$client" "$type"
      grant_tcc "$USER_TCC_DB" "kTCCServiceSystemPolicyAllFiles" "$client" "$type"
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$client" "$type" "com.apple.systemevents"
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$client" "$type" "com.apple.finder"
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$client" "$type" "com.apple.controlcenter"
    done

    # Homebrew and development tools (enhanced for installation permissions)
    echo "  Configuring development tool permissions..." >&2
    DEV_TOOLS=(
      "/opt/homebrew/bin/brew"
      "/usr/local/bin/brew"
      "/usr/bin/ditto"
      "/usr/bin/installer"
      "/usr/sbin/installer"
      "/usr/bin/codesign"
      "/usr/bin/hdiutil"
      "/usr/bin/diskutil"
      "/usr/bin/mkbom"
      "/Applications/Xcode.app"
      "/Applications/Visual Studio Code.app"
      "/Applications/Parallels Desktop.app"
    )

    for tool in "''${DEV_TOOLS[@]}"; do
      [ -e "$tool" ] || continue

      if [[ "$tool" == *.app ]]; then
        # App bundle
        bundle_id=$(/usr/bin/mdls -name kMDItemCFBundleIdentifier -r "$tool" 2>/dev/null || echo "")
        [ -n "$bundle_id" ] && client="$bundle_id" || client="$tool"
        type=0
      else
        # CLI binary
        client="$tool"
        type=1
      fi

      grant_tcc "$USER_TCC_DB" "kTCCServiceAccessibility" "$client" "$type"
      grant_tcc "$USER_TCC_DB" "kTCCServiceSystemPolicyAllFiles" "$client" "$type"
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$client" "$type" "com.apple.systemevents"
    done

    # Parallels Desktop - comprehensive virtualization permissions
    echo "  Configuring Parallels Desktop permissions..." >&2
    PARALLELS_PATHS=(
      "/Applications/Parallels Desktop.app"
    )

    for parallels_path in "''${PARALLELS_PATHS[@]}"; do
      [ -e "$parallels_path" ] || continue

      # Use verified bundle identifier
      client="com.parallels.desktop.console"
      type=0

      grant_tcc "$USER_TCC_DB" "kTCCServiceAccessibility" "$client" "$type"
      grant_tcc "$USER_TCC_DB" "kTCCServiceSystemPolicyAllFiles" "$client" "$type"
      grant_tcc "$USER_TCC_DB" "kTCCServiceCamera" "$client" "$type"
      grant_tcc "$USER_TCC_DB" "kTCCServiceMicrophone" "$client" "$type"
      grant_tcc "$USER_TCC_DB" "kTCCServiceScreenCapture" "$client" "$type"
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$client" "$type" "com.apple.systemevents"
    done

    # Apply TCC database changes and restart relevant services
    echo "  Applying TCC changes..." >&2
    (/usr/bin/sudo /usr/bin/killall tccd 2>/dev/null || true) &
    (/usr/bin/sudo /usr/bin/killall ControlCenter 2>/dev/null || true) &
    wait

    echo "✓ Comprehensive TCC permissions configured" >&2
  '';

  # --- System Security Configuration ----------------------------------------
  system.defaults = {
    # --- Screensaver Security -----------------------------------------------
    screensaver = {
      askForPassword = mkDefault false; # Disable password prompt after screensaver
      askForPasswordDelay = mkDefault 0; # No delay when disabled
    };
    # --- Global System Behavior ---------------------------------------------
    NSGlobalDomain = { };
    # --- Application Security -----------------------------------------------
    CustomUserPreferences = {
      "com.apple.security" = {
        GKAutoRearm = mkDefault false; # PERFORMANCE: Disable Gatekeeper auto-rearm
      };
      "com.apple.Safari" = {
        WarnAboutFraudulentWebsites = mkDefault true;
        "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically" = mkDefault false;
        SendDoNotTrackHTTPHeader = mkDefault true;
      };
      # --- Privacy & Telemetry Settings -------------------------------------
      "com.apple.assistant.support" = {
        "Assistant Enabled" = mkDefault false;
      };
      "com.apple.Siri" = {
        StatusMenuVisible = mkDefault false;
      };
      # --- Accessibility Security Settings ----------------------------------
      "com.apple.universalaccess" = {
        slowKey = mkDefault false;
        stickyKey = mkDefault false;
        grayscale = mkDefault false;
        closeViewHotkeysEnabled = mkDefault false;
        voiceOverOnOffKey = mkDefault false;
        keyboardAccessFocusRingTimeout = mkDefault 15;
      };

      # --- Additional Security Bypasses -------------------------------------
      "com.apple.LaunchServices" = {
        LSQuarantine = mkDefault false; # Disable quarantine for downloaded apps
      };

      # --- Developer Security Settings --------------------------------------
      "com.apple.dt.Xcode" = {
        "DVTPlugInManagerNonApplePlugIns-Xcode-14.0" = mkDefault { };
        DVTTextEditorTrimTrailingWhitespace = mkDefault false;
      };
    };
  };
}
