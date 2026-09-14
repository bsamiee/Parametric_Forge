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

    # Forge supplies casks absent from Homebrew's catalog; trust stays scoped to each fully qualified cask row.
    taps = [
      {
        name = "bsamiee/forge";
        clone_target = "git@github.com:bsamiee/Parametric_Forge.git";
      }
    ];

    # --- [MAC_APP_STORE]
    masApps = {
      Drafts = 1435957248;
    };

    # --- [ACTIVATION_BEHAVIOR]
    # Activation installs missing roster rows; native Homebrew commands own metadata, versions, and operator-installed rows. `brew bundle`
    # runs under sudo without the session environment; XDG_CONFIG_HOME points Homebrew at the same user configuration directory the shell
    # uses, where its own brew.env (the one owner of every HOMEBREW_* setting) and the tap trust store trust.json live (under ~/.homebrew when
    # the variable is unset).
    onActivation.extraEnv.XDG_CONFIG_HOME = "${config.users.users.${config.system.primaryUser}.home}/.config";
  };
}
