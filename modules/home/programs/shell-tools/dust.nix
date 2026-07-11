# Title         : dust.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/dust.nix
# ----------------------------------------------------------------------------
# Modern disk usage analyzer (du replacement)
{pkgs, ...}: let
  tomlFormat = pkgs.formats.toml {};

  dustConfig = {
    reverse = true; # Largest entries print first
    output-format = "si";
    skip-total = true; # Suppress the root total row
  };
in {
  xdg.configFile."dust/config.toml".source = tomlFormat.generate "dust-config" dustConfig;
}
