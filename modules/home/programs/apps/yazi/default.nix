# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/yazi/default.nix
# ----------------------------------------------------------------------------
# Yazi file manager: pinned official plugin monorepo, dracula flavor, RAR 7zz
{pkgs, ...}: let
  yaziPkg = pkgs.yazi.override {
    _7zz = pkgs._7zz-rar; # Prefer RAR-capable 7zip for archive support
  };

  officialPlugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "8cd50c622898d3ace3ca821f540241965308289a";
    hash = "sha256-f4y952sUF/lrHMX6enQts/obk2DeatqAcaVHfjTD65k=";
  };

  officialFlavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "4770a3467169bfdb0a3b11601921aaf27c100630";
    hash = "sha256-erZI0H5TxqFu2P917juL5PIB3LC0oJGKPcB1VibJDqo=";
  };
in {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    package = yaziPkg;

    plugins = {
      full-border = "${officialPlugins}/full-border.yazi";
      toggle-pane = "${officialPlugins}/toggle-pane.yazi";
      jump-to-char = "${officialPlugins}/jump-to-char.yazi";
      mount = "${officialPlugins}/mount.yazi";
      piper = "${officialPlugins}/piper.yazi";
      git = "${officialPlugins}/git.yazi";

      # Semantic command layer: open/quit/tab/paste/archive/scroll behaviors
      augment-command = pkgs.fetchFromGitHub {
        owner = "hankertrix";
        repo = "augment-command.yazi";
        rev = "dd2d6cf07f81cef543e37883352e30b91634ec86";
        hash = "sha256-sB2t3Gg+WdPG6OE8pD6VovD+x9nN21Jn8XydZZdTqCg=";
      };
    };

    flavors.dracula = "${officialFlavors}/dracula.yazi";
  };

  xdg.configFile = {
    "yazi/yazi.toml".source = ./yazi.toml;
    "yazi/keymap.toml".source = ./keymap.toml;
    "yazi/init.lua".source = ./init.lua;
    "yazi/theme.toml".source = ./theme.toml;
  };
}
