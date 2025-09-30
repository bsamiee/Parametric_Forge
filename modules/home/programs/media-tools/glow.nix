# Title         : glow.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/glow.nix
# ----------------------------------------------------------------------------
# Terminal markdown rendering for beautiful Yazi markdown preview

{ config, pkgs, lib, ... }:

let
  yamlFormat = pkgs.formats.yaml { };

  glowConfig = {
    style = "dark";
    mouse = true;
    showLineNumbers = true;  # Enables TUI line numbers
  };
in
{
  home.packages = [ pkgs.glow ];
  xdg.configFile."glow/glow.yml".source = yamlFormat.generate "glow-config" glowConfig;
}
