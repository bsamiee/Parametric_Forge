# Title         : security.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/settings/security.nix
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
  };
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
  # --- Sudoers Configuration -----------------------------------------------
  security.sudo = {
    extraConfig = ''
      # Allow passwordless system maintenance commands
      %admin ALL=(root) NOPASSWD: /usr/bin/mdutil *
      %admin ALL=(root) NOPASSWD: /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister *
      %admin ALL=(root) NOPASSWD: /usr/bin/defaults write /Library/Preferences/com.apple.security*
      %admin ALL=(root) NOPASSWD: /usr/sbin/spctl *
      %admin ALL=(root) NOPASSWD: /usr/bin/killall *
      %admin ALL=(root) NOPASSWD: /usr/bin/dscacheutil *
      %admin ALL=(root) NOPASSWD: /usr/sbin/softwareupdate *
      %admin ALL=(root) NOPASSWD: /usr/bin/xcode-select *
      %admin ALL=(root) NOPASSWD,SETENV: /usr/sbin/pkgutil *
      %admin ALL=(root) NOPASSWD: /usr/libexec/ApplicationFirewall/socketfilterfw *
      %admin ALL=(root) NOPASSWD: /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings *

      # Allow TCC reset operations
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

      # Developer tools and services
      %admin ALL=(root) NOPASSWD: /usr/bin/codesign *
      %admin ALL=(root) NOPASSWD: /usr/sbin/chown *
      %admin ALL=(root) NOPASSWD: /bin/chmod *
      %admin ALL=(root) NOPASSWD: /usr/bin/security *
      %admin ALL=(root) NOPASSWD: /usr/bin/plutil *
      %admin ALL=(root) NOPASSWD: /usr/libexec/PlistBuddy *

      # Installation tools
      %admin ALL=(root) NOPASSWD: /usr/bin/ditto *
      %admin ALL=(root) NOPASSWD: /usr/sbin/installer *
      %admin ALL=(root) NOPASSWD,SETENV: /usr/sbin/installer *

      # Allow 1Password CLI operations
      %admin ALL=(root) NOPASSWD: /opt/homebrew/bin/op *
    '';
  };
}
