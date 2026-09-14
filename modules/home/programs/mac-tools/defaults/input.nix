# Title         : input.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/mac-tools/defaults/input.nix
# ----------------------------------------------------------------------------
# Input device defaults for keyboard, mouse, and trackpad.
_: let
  # One trackpad row set serves both driver domains (USB and Bluetooth), as macOS keeps them in lockstep.
  trackpad = {
    Clicking = false;
    TrackpadRightClick = true;
    ActuationStrength = 0;
    FirstClickThreshold = 1;
    SecondClickThreshold = 1;
    Dragging = false;
    TrackpadThreeFingerDrag = false;
    TrackpadThreeFingerTapGesture = 0;
    TrackpadPinch = true;
    TrackpadRotate = true;
    TrackpadThreeFingerVertSwipeGesture = 2;
    TrackpadThreeFingerHorizSwipeGesture = 2;
    TrackpadCornerSecondaryClick = 0;
    TrackpadTwoFingerDoubleTapGesture = true; # smart zoom
    TrackpadFourFingerVertSwipeGesture = 2;
    TrackpadFourFingerHorizSwipeGesture = 2;
    TrackpadFourFingerPinchGesture = 2;
    TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
    TrackpadMomentumScroll = true;
    ActuateDetents = false;
    ForceSuppressed = true;
    DragLock = false;
  };
  # The Magic Mouse row set likewise projects onto both of its driver domains.
  magicmouse.MouseButtonMode = "TwoButton";
in {
  forge.userDefaults = {
    # --- [TRACKPAD_CONFIGURATION]
    "com.apple.AppleMultitouchTrackpad" =
      trackpad
      // {
        TrackpadFiveFingerPinchGesture = 2;
        TrackpadHandResting = true;
      };
    "com.apple.driver.AppleBluetoothMultitouch.trackpad" = trackpad;
    # --- [MAGIC_MOUSE_SETTINGS]
    "com.apple.AppleMultitouchMouse" = magicmouse;
    "com.apple.driver.AppleMultitouchMouse.mouse" = magicmouse;
    # --- [BLUETOOTH_MOUSE_CONFIGURATION]
    "com.apple.driver.AppleBluetoothMultitouch.mouse" = {
      MouseButtonMode = "TwoButton";
      MouseVerticalScroll = true;
      MouseHorizontalScroll = true;
      MouseMomentumScroll = true;
    };
    # --- [FN_KEY]
    # Fn cycles the three input sources (U.S., Persian-ISIRI 2901, Arabic); holding Fn exposes the hardware F1-F12 row per fnState below.
    # 0 = do nothing, 1 = change input source, 2 = show emoji & symbols, 3 = start dictation.
    "com.apple.HIToolbox".AppleFnUsageType = 1;
    # --- [GLOBAL_INPUT_BEHAVIOR]
    NSGlobalDomain = {
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      ApplePressAndHoldEnabled = false;
      AppleKeyboardUIMode = 2; # 2 = full keyboard access
      "com.apple.keyboard.fnState" = false;
      # Every text substitution off: each one rewrites text typed into a native field (a capital after a period, curly quotes in a path, a
      # period on a double space), which a driven keystroke never intends.
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      "com.apple.trackpad.enableSecondaryClick" = true;
      AppleEnableMouseSwipeNavigateWithScrolls = false;
      AppleEnableSwipeNavigateWithScrolls = false;
      "com.apple.mouse.linear" = true; # flat curve; driverless mice inherit the acceleration hump otherwise
    };
  };
}
