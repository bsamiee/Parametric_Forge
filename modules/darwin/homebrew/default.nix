{
  config,
  lib,
  host,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
  appStoreApps = {
    Drafts = 1435957248;
    Xcode = 497799835;
    "Microsoft Word" = 462054704;
    "Microsoft Excel" = 462058435;
    "MEGA VPN" = 6456784858;
  };
  appStoreMinutes = 60;
in {
  imports = [./casks.nix];

  # --- [MAC_APP_STORE]
  home-manager.users.${config.system.primaryUser} = {lib, ...}: {
    home.activation.appStoreApps = lib.hm.dag.entryAfter ["writeBoundary"] (lib.concatStrings (lib.mapAttrsToList (name: id: ''
        if [[ ! -d ${lib.escapeShellArg "/Applications/${name}.app"} ]]; then
          run ${lib.getExe' pkgs.coreutils "timeout"} ${toString (appStoreMinutes * 60)} ${lib.getExe pkgs.mas} install ${toString id} \
            || echo "app-store: ${name} is not installed (mas failed or passed ${toString appStoreMinutes} minutes), the next switch retries" >&2
        fi
      '')
      appStoreApps));
  };

  # --- [ENVIRONMENT]
  environment = {
    systemPackages = [pkgs.mas];
    variables.HOMEBREW_BUNDLE_FILE = "/etc/homebrew/Brewfile";
    etc = {
      "homebrew/Brewfile".text = config.homebrew.brewfile;
      "homebrew/brew.env".text = ''
        HOMEBREW_XDG_CONFIG_HOME=${config.home-manager.users.${config.system.primaryUser}.xdg.configHome}
        HOMEBREW_UPDATE_TO_TAG=1
        HOMEBREW_NO_ANALYTICS=1
        HOMEBREW_NO_ENV_HINTS=1
        HOMEBREW_NO_EMOJI=1
        HOMEBREW_NO_ASK=1
        HOMEBREW_CLEANUP_MAX_AGE_DAYS=3
        HOMEBREW_UPGRADE_GREEDY_CASKS=${toString config.forge.homebrew.latestCasks}
      '';
    };
  };

  homebrew = {
    enable = mkDefault true;

    taps = [
      {
        name = "bsamiee/forge";
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
