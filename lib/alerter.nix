# Title         : lib/alerter.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /lib/alerter.nix
# ----------------------------------------------------------------------------
# Alerter notification helpers for macOS

{ lib, ... }:

rec {
  # macOS System Sounds
  sounds = {
    default = "default";        # System default notification sound
    # Attention sounds
    basso = "Basso";            # Deep error/failure sound
    blow = "Blow";              # Soft blowing sound
    bottle = "Bottle";          # Pop bottle sound
    frog = "Frog";              # Frog croak
    funk = "Funk";              # Funky sound
    # Notification sounds
    glass = "Glass";            # Glass ping (success/completion)
    hero = "Hero";              # Heroic sound (important/warning)
    morse = "Morse";            # Morse code beep
    ping = "Ping";              # Simple ping
    pop = "Pop";                # Pop sound
    purr = "Purr";              # Cat purr
    sosumi = "Sosumi";          # "So sue me" sound
    submarine = "Submarine";    # Submarine sonar
    tink = "Tink";              # Light tink sound
  };

  # Build alerter command with smart defaults
  notify = {
    title,
    message,
    subtitle ? null,
    appIcon ? null,                 # Path to .icns icon file
    contentImage ? null,            # Additional image in notification body
    sound ? sounds.default,
    timeout ? null,                 # Seconds before auto-dismiss
    sender ? "com.apple.Terminal",  # Bundle ID for notification source
    group ? null,                   # Group ID for notification management
    closeLabel ? null,              # Custom close button text
    actions ? null,                 # List of action button labels
    dropdownLabel ? null,           # Label for action dropdown
    reply ? false,                  # Enable reply text field
    json ? false,                   # Output interaction as JSON
  }@args:
  let
    # Smart icon detection - use Terminal.app icon as default
    icon =
      if appIcon != null then appIcon
      else "/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns";

    # Build command parts
    baseCmd = "alerter";
    requiredArgs = [
      "-title '${lib.escape ["'"] title}'"
      "-message '${lib.escape ["'"] message}'"
    ];
    optionalArgs = lib.filter (x: x != "") [
      (lib.optionalString (subtitle != null) "-subtitle '${lib.escape ["'"] subtitle}'")
      (lib.optionalString (icon != "") "-appIcon '${icon}'")
      (lib.optionalString (contentImage != null) "-contentImage '${contentImage}'")
      (lib.optionalString (sound != "" && sound != null) "-sound ${sound}")
      (lib.optionalString (timeout != null) "-timeout ${toString timeout}")
      (lib.optionalString (group != null) "-group '${group}'")
      (lib.optionalString (closeLabel != null) "-closeLabel '${lib.escape ["'"] closeLabel}'")
      (lib.optionalString (actions != null) "-actions ${lib.concatStringsSep "," (map (a: "'${lib.escape ["'"] a}'") actions)}")
      (lib.optionalString (dropdownLabel != null) "-dropdownLabel '${lib.escape ["'"] dropdownLabel}'")
      (lib.optionalString reply "-reply")
      (lib.optionalString json "-json")
      "-sender ${sender}"
    ];
  in
    "${baseCmd} ${lib.concatStringsSep " " (requiredArgs ++ optionalArgs)}";

  # Preset notification types for common scenarios
  success = args: notify (args // {
    appIcon = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns";
    sound = sounds.glass;  # Glass ping for success
  });

  error = args: notify (args // {
    appIcon = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns";
    sound = sounds.basso;  # Deep error sound
  });

  warning = args: notify (args // {
    appIcon = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionBadgeIcon.icns";  # Fixed: use badge icon
    sound = sounds.hero;   # Heroic warning sound
  });

  # Interactive notification helper (with actions)
  interactive = args: notify (args // {
    json = true;  # Always output JSON for scripting
  });
}