_: let
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
    TrackpadTwoFingerDoubleTapGesture = 1;
    TrackpadFourFingerVertSwipeGesture = 2;
    TrackpadFourFingerHorizSwipeGesture = 2;
    TrackpadFourFingerPinchGesture = 2;
    TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
    TrackpadMomentumScroll = true;
    ActuateDetents = false;
    ForceSuppressed = true;
    DragLock = false;
  };
  magicmouse.MouseButtonMode = "TwoButton";
in {
  targets.darwin.defaults = {
    # --- [TRACKPAD_CONFIGURATION]
    "com.apple.AppleMultitouchTrackpad" = trackpad // {TrackpadFiveFingerPinchGesture = 2;};
    "com.apple.driver.AppleBluetoothMultitouch.trackpad" = trackpad // {TrackpadHandResting = true;};
    # --- [MAGIC_MOUSE_SETTINGS]
    "com.apple.AppleMultitouchMouse" = magicmouse;
    "com.apple.driver.AppleBluetoothMultitouch.mouse" =
      magicmouse
      // {
        MouseVerticalScroll = true;
        MouseHorizontalScroll = true;
        MouseMomentumScroll = true;
      };
    # --- [FN_KEY]
    "com.apple.HIToolbox".AppleFnUsageType = 1;
    # --- [GLOBAL_INPUT_BEHAVIOR]
    NSGlobalDomain = {
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      ApplePressAndHoldEnabled = false;
      AppleKeyboardUIMode = 2;
      "com.apple.keyboard.fnState" = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      "com.apple.trackpad.enableSecondaryClick" = true;
      "com.apple.trackpad.forceClick" = false;
      AppleEnableMouseSwipeNavigateWithScrolls = false;
      AppleEnableSwipeNavigateWithScrolls = false;
      "com.apple.mouse.linear" = true;
    };
  };
}
