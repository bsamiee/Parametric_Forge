# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/default.nix
# ----------------------------------------------------------------------------
# Language toolchain aggregator; publishes the package-admission ledger at a stable XDG path for register browsers and receipt rails.
{pkgs, ...}: {
  imports = [
    # Shared tooling
    ./dev-tools.nix
    ./db-tools.nix
    ./scientific-tools.nix

    # Languages
    ./apple-tools.nix
    ./lua-tools.nix
    ./node-tools.nix
    ./python-tools.nix
  ];

  # Machine-readable projection of overlays/manifest.nix with live-resolved admission versions; consumers read rows here, never derivation source.
  xdg.dataFile."forge/packages/manifest.json".source = "${pkgs.forge-package-manifest}/share/forge/manifest.json";
}
