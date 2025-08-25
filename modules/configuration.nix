# Title         : modules/configuration.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/configuration.nix
# ----------------------------------------------------------------------------
# Single source of truth for merging default and user-provided settings.

{
  lib,
  config,
  myLib,
  context,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    mkIf
    recursiveUpdate
    ;

  defaultConfig = myLib.configDefaults { inherit (context) isDarwin; };

  configPath = ../configuration.json;
  hasConfig = builtins.pathExists configPath;
  userConfig = if hasConfig then builtins.fromJSON (builtins.readFile configPath) else { };

  cfg = recursiveUpdate defaultConfig userConfig;
in
{
  options.configuration = {
    # --- User Settings ------------------------------------------------------
    settings = mkOption {
      type = types.attrs;
      default = cfg;
      internal = true;
      description = "Merged configuration from TUI";
    };

    # --- Default Configuration ----------------------------------------------
    defaults = mkOption {
      type = types.attrs;
      default = defaultConfig;
      internal = true;
      description = "Default configuration structure";
    };

    # --- Computed State -----------------------------------------------------
    isConfigured = mkOption {
      type = types.bool;
      internal = true;
      default = cfg.gitConfig.email or "" != "";
    };
  };

  config = lib.mkMerge [
    # --- Apply Git Configuration --------------------------------------------
    (mkIf (cfg.gitConfig.username != "" && cfg.gitConfig.email != "") {
      programs.git = {
        userName = cfg.gitConfig.username;
        userEmail = cfg.gitConfig.email;
      };
    })

    # --- Apply 1Password Integration ----------------------------------------
    # Note: SSH agent configuration is handled in 01.home/00.core/programs/ssh.nix
    # which respects the onePassword.sshAgent setting with a default of true

    # --- Apply Touch ID (Darwin only) ---------------------------------------
    # Note: Touch ID must be configured at system level, not in home-manager

    # --- Apply Cachix -------------------------------------------------------
    (mkIf (cfg.integrations.cachix or false) {
      nix.settings.substituters = [ "https://parametric-forge.cachix.org" ];
    })
  ];
}
