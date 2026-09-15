# Title         : glow.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/glow.nix
# ----------------------------------------------------------------------------
# Terminal markdown pager; Yazi previews markdown through rich (apps/yazi/default.nix previewer rows), never through glow.
{pkgs, ...}: let
  yamlFormat = pkgs.formats.yaml {};

  glowConfig = {
    style = "dark";
    mouse = true;
    showLineNumbers = true;
  };
in {
  xdg.configFile."glow/glow.yml".source = yamlFormat.generate "glow-config" glowConfig;
}
