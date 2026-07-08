# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/wezterm/default.nix
# ----------------------------------------------------------------------------
# WezTerm terminal emulator configuration; palette.lua is generated from the
# shared Dracula owner (programs.zellij.colors) so hex values exist once.
{
  config,
  lib,
  ...
}: let
  inherit (config.programs.zellij) colors;
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
      ${lib.concatStrings (lib.mapAttrsToList (name: c: "  ${name} = \"${c.hex}\",\n") colors)}}
    '';
  };
}
