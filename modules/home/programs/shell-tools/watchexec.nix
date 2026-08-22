# Title         : watchexec.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/watchexec.nix
# ----------------------------------------------------------------------------
# watchexec owner: the package plus the global ignore estate (the noise taxonomy and its rendering).
{
  config,
  pkgs,
  ...
}: {
  home.packages = [pkgs.watchexec];
  xdg.configFile."watchexec/ignore".text = config.forge.ignoreEstate.text;
}
