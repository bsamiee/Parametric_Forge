# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/default.nix
# ----------------------------------------------------------------------------
# Homebrew configuration and aggregator
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault;
in {
  imports = [
    ./brews.nix
    ./casks.nix
  ];

  homebrew = {
    enable = mkDefault true;

    # --- [MAC_APP_STORE]
    masApps = {
      Drafts = 1435957248;
    };

    # --- [ACTIVATION_BEHAVIOR]
    # Activation installs missing roster rows; native Homebrew commands own metadata, versions, and operator-installed rows.
    onActivation.extraEnv = {
      HOMEBREW_NO_ANALYTICS = mkDefault "1";
      HOMEBREW_NO_ENV_HINTS = mkDefault "1";
      XDG_CONFIG_HOME = mkDefault "/Users/${config.system.primaryUser}/.config";
    };
  };
}
