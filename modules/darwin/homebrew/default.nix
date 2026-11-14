{
  config,
  lib,
  host,
  ...
}: let
  inherit (lib) mkDefault;
  brewfile = "homebrew/Brewfile";
in {
  imports = [./casks.nix];

  # --- [ENVIRONMENT]
  environment = {
    etc = {
      ${brewfile}.text = config.homebrew.brewfile;
      "homebrew/brew.env".text = ''
        HOMEBREW_BUNDLE_FILE=/etc/${brewfile}
        HOMEBREW_XDG_CONFIG_HOME=${config.home-manager.users.${config.system.primaryUser}.xdg.configHome}
        HOMEBREW_UPDATE_TO_TAG=1
        HOMEBREW_NO_ANALYTICS=1
        HOMEBREW_NO_ENV_HINTS=1
        HOMEBREW_NO_EMOJI=1
        HOMEBREW_NO_ASK=1
        HOMEBREW_CLEANUP_MAX_AGE_DAYS=3
        HOMEBREW_UPGRADE_GREEDY_CASKS=${toString (map (cask: lib.last (lib.splitString "/" cask.name)) (lib.filter (cask: cask.greedy == true) config.homebrew.casks))}
      '';
    };
  };

  homebrew = {
    enable = mkDefault true;

    taps = [
      {
        name = "bsamiee/parametric-forge";
        clone_target = host.flakeRoot;
        trusted = true;
      }
    ];

    # --- [ACTIVATION_BEHAVIOR]
    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };
  };
}
