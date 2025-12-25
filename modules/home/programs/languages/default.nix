# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/default.nix
# ----------------------------------------------------------------------------
# Language toolchain aggregator
{...}: {
  imports = [
    # LSPs
    ./lsp.nix

    # Shared tooling
    ./dev-tools.nix
    ./db-tools.nix

    # Languages
    ./lua-tools.nix
    ./node-tools.nix
    ./python-tools.nix
  ];
}
