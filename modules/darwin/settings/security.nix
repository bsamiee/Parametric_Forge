# Title         : security.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/settings/security.nix
# ----------------------------------------------------------------------------
# Security, PAM, certificates, and firewall configuration for Darwin.
{
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault;
in {
  # Debugger/developer-tool authorization without per-launch prompts: developer mode plus _developer membership are idempotent root activations. TCC
  # stays reset-only (tccutil); no TCC.db writes, no PPPC on this unmanaged host.
  system.activationScripts.postActivation.text = ''
    /usr/sbin/DevToolsSecurity -status | grep -q "currently enabled" \
      || /usr/sbin/DevToolsSecurity -enable
    dsmemberutil checkmembership -U ${config.system.primaryUser} -G _developer | grep -q "^user is a member" \
      || /usr/sbin/dseditgroup -o edit -t user -a ${config.system.primaryUser} _developer
  '';

  # --- [SECURITY_CONFIGURATION]
  security = {
    # --- [PAM_AUTHENTICATION]
    pam.services.sudo_local = {
      enable = mkDefault true;
      touchIdAuth = mkDefault true;
      watchIdAuth = mkDefault false;
      reattach = mkDefault false;
    };
    # --- [CERTIFICATE_MANAGEMENT]
    pki = {
      installCACerts = mkDefault true;
      certificateFiles = [];
      certificates = [];
      caCertificateBlacklist = [];
    };
  };
  # --- [SYSTEM_SECURITY_CONFIGURATION]
  system.defaults = {
    # --- [SCREENSAVER_SECURITY]
    screensaver = {
      askForPassword = mkDefault false; # Disable password prompt after screensaver
      askForPasswordDelay = mkDefault 0; # No delay when disabled
    };
    # --- [APPLICATION_SECURITY]
    CustomUserPreferences = {
      # --- [PRIVACY_TELEMETRY_SETTINGS]
      "com.apple.assistant.support" = {
        "Assistant Enabled" = mkDefault false;
      };
      "com.apple.Siri" = {
        StatusMenuVisible = mkDefault false;
      };
      # --- [ACCESSIBILITY_SECURITY_SETTINGS]
      "com.apple.universalaccess" = {
        slowKey = mkDefault false;
        stickyKey = mkDefault false;
        grayscale = mkDefault false;
        closeViewHotkeysEnabled = mkDefault false;
        voiceOverOnOffKey = mkDefault false;
        keyboardAccessFocusRingTimeout = mkDefault 15;
      };
      # LSQuarantine stays disabled through the first-class owner: system.defaults.LaunchServices.LSQuarantine in settings/system.nix.
      # --- [DEVELOPER_SECURITY_SETTINGS]
      "com.apple.dt.Xcode" = {
        DVTTextEditorTrimTrailingWhitespace = mkDefault false;
      };
    };
  };
  # --- [SUDOERS_CONFIGURATION]
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

      # Allow service automation used by system maintenance workflows
      %admin ALL=(root) NOPASSWD: /bin/launchctl *
      %admin ALL=(root) NOPASSWD: /usr/bin/osascript *

      # Deploy rail: regex rows pin every argv exactly (arg globs match spaces and slashes, regex rows do not) — lifecycle verbs on the installed
      # darwin-rebuild, exact-closure activation, profile registration
      %admin ALL=(root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild ^(--list-generations|--rollback|--switch-generation [0-9]+)$
      %admin ALL=(root) NOPASSWD: ^/nix/store/[a-z0-9]{32}-darwin-system-[^/]+/sw/bin/darwin-rebuild$ activate
      %admin ALL=(root) NOPASSWD: /nix/var/nix/profiles/default/bin/nix-env ^-p /nix/var/nix/profiles/system --set /nix/store/[a-z0-9]{32}-darwin-system-[^[:space:]/]+$

      # Maintenance rail: bounded system-generation retention (exact args)
      %admin ALL=(root) NOPASSWD: /nix/var/nix/profiles/default/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations +5

      # Determinate custom-config adoption: move the installer-written real file aside so activation's /etc collision guard passes (module owns the symlink)
      %admin ALL=(root) NOPASSWD: /bin/mv /etc/nix/nix.custom.conf /etc/nix/nix.custom.conf.before-determinate-module

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

    '';
  };
}
