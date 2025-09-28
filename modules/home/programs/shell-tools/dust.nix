# Title         : dust.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/dust.nix
# ----------------------------------------------------------------------------
# Modern disk usage analyzer (du replacement)

{ config, lib, pkgs, ... }:

let
  tomlFormat = pkgs.formats.toml { };

  dustConfig = {
    reverse = true;                  # Normal sort order (largest first)
    ignore-hidden = true;            # Ignore dotfiles and hidden directories
    output-format = "si";
    skip-total = true;               # Show total size
  };
in
{
  home.packages = [ pkgs.du-dust ];
  xdg.configFile."dust/config.toml".source = tomlFormat.generate "dust-config" dustConfig;
}
