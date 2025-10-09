# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/yazi
# ----------------------------------------------------------------------------
# Yazi file manager with nixpkgs plugins

{ config, lib, pkgs, ... }:

let
  yaziPkg = pkgs.yazi.override {
    _7zz = pkgs._7zz-rar;  # Prefer RAR-capable 7zip for archive support
  };
in {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    package = yaziPkg;
    plugins = {
      full-border = pkgs.yaziPlugins.full-border;
      toggle-pane = pkgs.yaziPlugins.toggle-pane;
      jump-to-char = pkgs.yaziPlugins.jump-to-char;
      mount = pkgs.yaziPlugins.mount;

      # Third-party plugins (not in nixpkgs)
      augment-command = pkgs.fetchFromGitHub {
        owner = "hankertrix";
        repo = "augment-command.yazi";
        rev = "120406f79b6a5bf4db6120dd99c1106008ada5cf";
        hash = "sha256-t9X7cNrMR3fFqiM13COQbBDHYr8UKgxW708V6ndZVgY=";
      };
    };
  };

  xdg.configFile = {
    "yazi/yazi.toml".source = ./yazi.toml;
    "yazi/keymap.toml".source = ./keymap.toml;
    "yazi/init.lua".source = ./init.lua;
    "yazi/theme.toml".source = ./theme.toml;

    # --- Custom Plugins -----------------------------------------------------
    "yazi/plugins/piper.yazi/main.lua".source = ./plugins/piper.yazi/main.lua;
    "yazi/plugins/auto-layout.yazi/main.lua".source = ./plugins/auto-layout.yazi/main.lua;
    "yazi/plugins/sidebar-status.yazi/main.lua".source = ./plugins/sidebar-status.yazi/main.lua;
  };
}
