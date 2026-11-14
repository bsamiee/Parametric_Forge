# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/default.nix
# ----------------------------------------------------------------------------
# Machine-wide command-line tools by domain.
_: {
  imports = [
    ./dev-tools.nix
    ./db-tools.nix
    ./scientific-tools.nix
    ./node-tools.nix
  ];
}
