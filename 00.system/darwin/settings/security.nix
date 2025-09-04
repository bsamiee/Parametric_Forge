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
        
        # yabai scripting addition (secure hash validation)
        %admin ALL=(root) NOPASSWD: sha256:b5cf0d0286073361861852d5d7b4e706bc7a94780da3e1807250a2020f6cdc0d /opt/homebrew/bin/yabai --load-sa
        
        # Window manager tools (sketchybar, skhd, borders)
        %admin ALL=(root) NOPASSWD: /opt/homebrew/bin/sketchybar *
        %admin ALL=(root) NOPASSWD: /opt/homebrew/bin/skhd *
        %admin ALL=(root) NOPASSWD: /opt/homebrew/bin/borders *
        
        # Developer tools and services
        %admin ALL=(root) NOPASSWD: /usr/bin/codesign *
        %admin ALL=(root) NOPASSWD: /usr/sbin/chown *
        %admin ALL=(root) NOPASSWD: /bin/chmod *
        %admin ALL=(root) NOPASSWD: /usr/bin/security *
        %admin ALL=(root) NOPASSWD: /usr/bin/plutil *
        %admin ALL=(root) NOPASSWD: /usr/libexec/PlistBuddy *
        
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

  # --- TCC Permission Automation (requires SIP disabled) --------------------
  system.activationScripts.preActivation.text = ''
    echo "Configuring TCC permissions..." >&2
    
    # Find primary user (first non-system user in /Users)  
    PRIMARY_USER=""
    for user in /Users/*; do
      [ -d "$user" ] && [ "$(basename "$user")" != "Shared" ] && PRIMARY_USER="$(basename "$user")" && break
    done
    USER_TCC_DB="/Users/$PRIMARY_USER/Library/Application Support/com.apple.TCC/TCC.db"
    
    # Grant TCC permission function
    grant_tcc() {
      local db="$1" service="$2" client="$3" type="''${4:-0}" target="''${5:-}"
      [ -f "$db" ] || return
      /usr/bin/sqlite3 "$db" "SELECT 1 FROM access WHERE service='$service' AND client='$client'" | grep -q 1 && return
      
      if [ -n "$target" ]; then
        # AppleEvents with target
        /usr/bin/sqlite3 "$db" "INSERT INTO access (service,client,client_type,auth_value,auth_reason,auth_version,indirect_object_identifier,flags,last_modified) VALUES ('$service','$client',$type,2,4,1,'$target',0,strftime('%s','now'))"
      else
        # Standard permission
        /usr/bin/sqlite3 "$db" "INSERT INTO access (service,client,client_type,auth_value,auth_reason,auth_version,flags,last_modified) VALUES ('$service','$client',$type,2,1,1,0,strftime('%s','now'))"
      fi
      echo "  ✓ Granted $service to $client" >&2
    }
    
    # Shell automation permissions
    for shell in /bin/sh /bin/bash /usr/bin/osascript; do
      grant_tcc "$USER_TCC_DB" "kTCCServiceAccessibility" "$shell" 1
      grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$shell" 1 "com.apple.systemevents"
    done
    grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "/usr/bin/osascript" 1 "com.apple.controlcenter"
    
    # Daemon services needing accessibility (from launchd services)
    for daemon in font-cache-daemon home-maintenance-daemon npm-daemon op-ssh-setup security-daemon sys-maintenance-daemon; do
      grant_tcc "$USER_TCC_DB" "kTCCServiceAccessibility" "$daemon" 1
    done
    
    # SketchyBar permissions  
    SKETCHYBAR_BUNDLE="sketchybar-555549443c0503b403b03a959788e7170ecae04a"
    grant_tcc "$USER_TCC_DB" "kTCCServiceAccessibility" "$SKETCHYBAR_BUNDLE" 0
    grant_tcc "$USER_TCC_DB" "kTCCServiceBluetoothAlways" "$SKETCHYBAR_BUNDLE" 0
    grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$SKETCHYBAR_BUNDLE" 0 "com.apple.systemevents"
    grant_tcc "$USER_TCC_DB" "kTCCServiceAppleEvents" "$SKETCHYBAR_BUNDLE" 0 "com.apple.controlcenter"
    
    # yabai accessibility
    [ -f "/opt/homebrew/bin/yabai" ] && grant_tcc "$USER_TCC_DB" "kTCCServiceAccessibility" "/opt/homebrew/bin/yabai" 1
    
    # Apply TCC changes (non-blocking)
    (/usr/bin/sudo /usr/bin/killall tccd 2>/dev/null || true) &
    echo "TCC permissions configured" >&2
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
        "DVTPlugInManagerNonApplePlugIns-Xcode-14.0" = mkDefault {};
        DVTTextEditorTrimTrailingWhitespace = mkDefault false;
      };
    };
  };
}
