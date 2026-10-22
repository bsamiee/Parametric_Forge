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
  host,
  ...
}: let
  inherit (lib) mkDefault;
in {
  imports = [./casks.nix];

  # --- [ENVIRONMENT]
  # bin/brew exports /etc/homebrew/brew.env first in every context (shells, agents, activation's sudo `brew bundle`): the one owner of the standing
  # HOMEBREW_* rows. Values are literal (no quotes, no expansion). HOMEBREW_XDG_CONFIG_HOME is bin/brew's own fallback when XDG_CONFIG_HOME is
  # unset, so activation and every shell read the one trust store under the Home Manager config root. Homebrew updates itself to the newest stable
  # tag even after a developer command; a zero-argument upgrade carries the :latest rows, while activation's bundle stays non-greedy.
  environment.etc."homebrew/brew.env".text = ''
    HOMEBREW_XDG_CONFIG_HOME=${config.home-manager.users.${config.system.primaryUser}.xdg.configHome}
    HOMEBREW_UPDATE_TO_TAG=1
    HOMEBREW_NO_ANALYTICS=1
    HOMEBREW_NO_ENV_HINTS=1
    HOMEBREW_NO_EMOJI=1
    HOMEBREW_NO_ASK=1
    HOMEBREW_CLEANUP_MAX_AGE_DAYS=3
    HOMEBREW_UPGRADE_GREEDY_CASKS=wezterm@nightly blender@daily font-sf-pro font-sf-arabic font-markazi-text font-reem-kufi font-qahiri
  '';

  homebrew = {
    enable = mkDefault true;
    global.brewfile = true;

    # The tap clones this checkout: a committed cask reaches the next activation without a push or SSH, and the local clone hardlinks the
    # checkout's objects. A custom-remote tap is trusted by its remote, which this row writes.
    taps = [
      {
        name = "bsamiee/forge";
        clone_target = host.flakeRoot;
        trusted = true;
      }
    ];

    # --- [MAC_APP_STORE]
    masApps = {
      Drafts = 1435957248;
      "Microsoft Word" = 462054704;
      "Microsoft Excel" = 462058435;
      "MEGA VPN" = 6456784858;
    };

    # --- [ACTIVATION_BEHAVIOR]
    # Activation updates Homebrew and the catalog, installs missing rows, and upgrades every outdated one: an `auto_updates` cask only when its
    # bundle trails the tap, and Homebrew reopens the apps it quit. Cleanup stays with the manual Homebrew pass, so operator installs survive.
    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };
  };
}
