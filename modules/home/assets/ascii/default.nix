# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/assets/ascii/default.nix
# ----------------------------------------------------------------------------
# ASCII art assets for terminal applications

_: {
  # --- [FASTFETCH_ASCII_ART]
  xdg.configFile = {
    "fastfetch/logo.txt".source = ./irgc-ascii-art.txt;
  };
}
