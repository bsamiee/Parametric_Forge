# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/assets/default.nix
# ----------------------------------------------------------------------------
# Asset files aggregator - fastfetch ASCII art and desktop wallpaper
{...}: {
  imports = [
    ./ascii
    ./wallpaper
  ];
}
