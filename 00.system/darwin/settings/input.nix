# Title         : 00.system/darwin/settings/input.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/settings/input.nix
# ----------------------------------------------------------------------------
# Input device configuration for keyboard, mouse, and trackpad.

{ lib, ... }:

let
  inherit (lib) mkDefault;
in
{
  system = {
    # --- Keyboard Hardware Remapping ----------------------------------------
    keyboard = {
      enableKeyMapping = mkDefault false;
      nonUS.remapTilde = mkDefault false;
      remapCapsLockToControl = mkDefault false;
      remapCapsLockToEscape = mkDefault false;
      swapLeftCommandAndLeftAlt = mkDefault false;
      swapLeftCtrlAndFn = mkDefault false;
    };
    # --- System Input Defaults ----------------------------------------------
    defaults = {
      # --- Trackpad Configuration -------------------------------------------
      trackpad = {
        Clicking = mkDefault false;
        TrackpadRightClick = mkDefault true;
        ActuationStrength = mkDefault 0;
        FirstClickThreshold = mkDefault 1;
        SecondClickThreshold = mkDefault 1;
        Dragging = mkDefault false;
        TrackpadThreeFingerDrag = mkDefault false;
        TrackpadThreeFingerTapGesture = mkDefault 0;
      };
      # --- Magic Mouse Settings ---------------------------------------------
      magicmouse = {
        MouseButtonMode = mkDefault "TwoButton";
      };
      # --- Global Input Behavior --------------------------------------------
      NSGlobalDomain = {
        InitialKeyRepeat = mkDefault 15;
        KeyRepeat = mkDefault 2;
        ApplePressAndHoldEnabled = mkDefault false;
        AppleKeyboardUIMode = mkDefault 3;
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
      # --- Advanced Input Customizations ------------------------------------
      CustomUserPreferences = {
        # --- Trackpad Gestures ----------------------------------------------
        "com.apple.AppleMultitouchTrackpad" = {
          TrackpadPinch = mkDefault true;
          TrackpadRotate = mkDefault true;
          TrackpadThreeFingerVertSwipeGesture = mkDefault 2;
          TrackpadFourFingerVertSwipeGesture = mkDefault 2;
          TrackpadFourFingerHorizSwipeGesture = mkDefault 2;
          TrackpadFourFingerPinchGesture = mkDefault 2;
          TrackpadFiveFingerPinchGesture = mkDefault 2;
          TrackpadTwoFingerDoubleTapGesture = mkDefault 1;
          TrackpadTwoFingerFromRightEdgeSwipeGesture = mkDefault 3;
          TrackpadHandResting = mkDefault true;
          TrackpadMomentumScroll = mkDefault true;
          ActuateDetents = mkDefault false;
          ForceSuppressed = mkDefault true;
          DragLock = mkDefault false;
        };
        # --- Bluetooth Mouse Configuration ----------------------------------
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
