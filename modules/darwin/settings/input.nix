# Title         : input.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/settings/input.nix
# ----------------------------------------------------------------------------
# Input device configuration for keyboard, mouse, and trackpad.
{lib, ...}: let
  inherit (lib) mkDefault;
in {
  system = {
    # --- [KEYBOARD_HARDWARE_REMAPPING]
    keyboard = {
      enableKeyMapping = mkDefault false;
      nonUS.remapTilde = mkDefault false;
      remapCapsLockToControl = mkDefault false;
      remapCapsLockToEscape = mkDefault false;
      swapLeftCommandAndLeftAlt = mkDefault false;
      swapLeftCtrlAndFn = mkDefault false;
    };
    # --- [SYSTEM_INPUT_DEFAULTS]
    defaults = {
      # --- [TRACKPAD_CONFIGURATION]
      trackpad = {
        Clicking = mkDefault false;
        TrackpadRightClick = mkDefault true;
        ActuationStrength = mkDefault 0;
        FirstClickThreshold = mkDefault 1;
        SecondClickThreshold = mkDefault 1;
        Dragging = mkDefault false;
        TrackpadThreeFingerDrag = mkDefault false;
        TrackpadThreeFingerTapGesture = mkDefault 0;
        TrackpadPinch = mkDefault true;
        TrackpadRotate = mkDefault true;
        TrackpadThreeFingerVertSwipeGesture = mkDefault 2;
        TrackpadFourFingerVertSwipeGesture = mkDefault 2;
        TrackpadFourFingerHorizSwipeGesture = mkDefault 2;
        TrackpadFourFingerPinchGesture = mkDefault 2;
        TrackpadTwoFingerFromRightEdgeSwipeGesture = mkDefault 3;
        TrackpadMomentumScroll = mkDefault true;
        ActuateDetents = mkDefault false;
        ForceSuppressed = mkDefault true;
        DragLock = mkDefault false;
      };
      # --- [MAGIC_MOUSE_SETTINGS]
      magicmouse = {
        MouseButtonMode = mkDefault "TwoButton";
      };
      # --- [GLOBAL_INPUT_BEHAVIOR]
      NSGlobalDomain = {
        InitialKeyRepeat = mkDefault 15;
        KeyRepeat = mkDefault 2;
        ApplePressAndHoldEnabled = mkDefault false;
        AppleKeyboardUIMode = mkDefault 2; # 2 = full keyboard access on Sonoma+
        "com.apple.keyboard.fnState" = mkDefault false;
        NSAutomaticCapitalizationEnabled = mkDefault true;
        NSAutomaticSpellingCorrectionEnabled = mkDefault true;
        NSAutomaticPeriodSubstitutionEnabled = mkDefault true;
        NSAutomaticQuoteSubstitutionEnabled = mkDefault true;
        NSAutomaticDashSubstitutionEnabled = mkDefault true;
        NSAutomaticInlinePredictionEnabled = mkDefault false;
        "com.apple.mouse.tapBehavior" = mkDefault null;
        "com.apple.trackpad.enableSecondaryClick" = mkDefault true;
        "com.apple.trackpad.trackpadCornerClickBehavior" = mkDefault null;
        "com.apple.trackpad.scaling" = mkDefault null;
        "com.apple.trackpad.forceClick" = mkDefault null;
        AppleEnableMouseSwipeNavigateWithScrolls = mkDefault false;
        AppleEnableSwipeNavigateWithScrolls = mkDefault false;
        "com.apple.swipescrolldirection" = mkDefault null;
      };
      # --- [ADVANCED_INPUT_CUSTOMIZATIONS]
      CustomUserPreferences = {
        # Trackpad keys without first-class nix-darwin owners at the pinned rev; the rest live on system.defaults.trackpad.* above.
        "com.apple.AppleMultitouchTrackpad" = {
          TrackpadTwoFingerDoubleTapGesture = mkDefault 1; # first-class owner is bool-only; keep int here
          TrackpadFiveFingerPinchGesture = mkDefault 2;
          TrackpadHandResting = mkDefault true;
        };
        # --- [BLUETOOTH_MOUSE_CONFIGURATION]
        "com.apple.driver.AppleBluetoothMultitouch.mouse" = {
          MouseButtonMode = mkDefault "TwoButton";
          MouseVerticalScroll = mkDefault true;
          MouseHorizontalScroll = mkDefault true;
          MouseMomentumScroll = mkDefault true;
        };
      };
    };
  };
}
