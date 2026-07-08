# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/wezterm/default.nix
# ----------------------------------------------------------------------------
# WezTerm terminal emulator configuration; palette.lua is generated from the
# shared Dracula owner (programs.zellij.colors) and paths.lua from the shared
# PATH owner (modules/common/toolchain-env.nix) so both truths exist once.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.programs.zellij) colors;
  toolchainEnv = import ../../../../common/toolchain-env.nix {
    inherit lib pkgs;
    home = config.home.homeDirectory;
    username = config.home.username;
    xdgCacheHome = config.xdg.cacheHome;
  };
in {
  xdg.configFile = {
    "wezterm/wezterm.lua".source = ./wezterm.lua;
    "wezterm/appearance.lua".source = ./appearance.lua;
    "wezterm/behavior.lua".source = ./behavior.lua;
    "wezterm/keys.lua".source = ./keys.lua;
    "wezterm/mouse.lua".source = ./mouse.lua;
    "wezterm/integration.lua".source = ./integration.lua;
    "wezterm/palette.lua".text = ''
      -- Generated from programs.zellij.colors, the shared Forge Dracula owner.
      return {
      ${lib.concatStrings (lib.mapAttrsToList (name: c: "  [\"${name}\"] = \"${c.hex}\",\n") colors)}}
    '';
    "wezterm/paths.lua".text = ''
      -- Generated from modules/common/toolchain-env.nix, the shared PATH owner.
      return {
        path = "${lib.concatStringsSep ":" toolchainEnv.launchdPathEntries}",
        zellij = "${pkgs.zellij}/bin/zellij",
      }
    '';
  };
}
