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
        # Allow passwordless yabai scripting addition loading (both Nix and Homebrew paths)
        %admin ALL=(root) NOPASSWD: /run/current-system/sw/bin/yabai --load-sa
        %admin ALL=(root) NOPASSWD: /opt/homebrew/bin/yabai --load-sa
        %admin ALL=(root) NOPASSWD: /usr/local/bin/yabai --load-sa

        # Allow passwordless system maintenance commands
        %admin ALL=(root) NOPASSWD: /usr/bin/mdutil *
        %admin ALL=(root) NOPASSWD: /usr/bin/tmutil addexclusion *
        %admin ALL=(root) NOPASSWD: /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister *
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
        GKAutoRearm = mkDefault true; # Enable Gatekeeper auto-rearm for security
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
    };
  };
}
