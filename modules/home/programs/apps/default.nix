# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/default.nix
# ----------------------------------------------------------------------------
# GUI and terminal applications aggregator
{...}: {
  imports = [
    ./claude-code-statusline.nix
    ./nvim
    ./wezterm
    ./yazi
    ./zellij
  ];
}
