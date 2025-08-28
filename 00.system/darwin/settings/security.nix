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
        # Allow passwordless yabai scripting addition loading
        # Note: Path will be resolved by the yabai package installation
        %admin ALL=(root) NOPASSWD: /run/current-system/sw/bin/yabai --load-sa
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
      askForPassword = mkDefault true;
      askForPasswordDelay = mkDefault 5;
    };
    # --- Global System Behavior ---------------------------------------------
    NSGlobalDomain = { };
    # --- Application Security -----------------------------------------------
    CustomUserPreferences = {
      "com.apple.security" = {
        GKAutoRearm = mkDefault true;
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
